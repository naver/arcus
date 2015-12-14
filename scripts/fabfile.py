#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# fabfile.py -- distribute Arcus cluster with fabric
#

import sys
import os
import site

# FIXME Add Arcus's python lib directory to PYTHONPATH
ARCUS_PATH = os.path.normpath(os.path.dirname(os.path.realpath(__file__)) + '/..')
ARCUS_SITE = os.path.join(ARCUS_PATH, 'lib/python/site-packages')
site.addsitedir(ARCUS_SITE)

#import logging
#logging.basicConfig(level=logging.DEBUG)

from fabric.api import *
from fabric.colors import *
from fabric.contrib.files import *
from fabric.contrib.project import *
from fabric.task_utils import merge

from functools import wraps
from collections import namedtuple
from lib.zk import ArcusZooKeeper
from lib.pptable import pptable
import json
import time
import socket

#--------------
# User Settings
#--------------

env.timeout = 1
env.use_ssh_config = False

#----Do not change below here----#

env.ARCUS_PATH = ARCUS_PATH
env.ZOOKEEPER_PATH = os.path.join(ARCUS_PATH, 'zookeeper')
env.TEMPLATE_PATH = os.path.join(ARCUS_PATH, 'scripts/conf')

env.disable_known_hosts = True
env.always_use_pty = False
env.forward_agent = True

#----------
# Utilities
#----------

def is_localhost(host=None):
  """
  Check if the current host is localhost.
  """
  if not host:
    host=env.host

  if '127.0.0.1' == host or 'localhost' == host:
    return True

  if host == socket.gethostname():
    return True

  if host == socket.gethostbyname(socket.gethostname()):
    return True
    
  return False

@wraps(run)
def run_or_local(*args, **kargs):
  """
  A crude function to select run() or local().
  We need this not to use SSH for localhost.

  Fabric does not have this feature...oops
  Check https://github.com/fabric/fabric/issues/98
  """
  dir = kargs.pop('cd', None)
  if is_localhost():
    kargs.pop('warn_only', None)
    kargs.pop('timeout', None)
    kargs['shell'] = '/bin/bash'
    if dir is None:
      return local(*args, **kargs)
    else:
      with lcd(dir):
        return local(*args, **kargs)
  else:
    kargs.pop('capture', None)
    if dir is None:
      return run(*args, **kargs)
    else:
      with cd(dir):
        return run(*args, **kargs)

def _expand_path(path):
    return '"$(echo %s)"' % path

def upload_template_local(filename, destination, context=None, use_jinja=False,
  template_dir=None, use_sudo=False, backup=True, mirror_local_mode=False, mode=None):
  """
  upload_template for localhost
  """
  # Normalize destination to be an actual filename, due to using StringIO
  with settings(hide('everything'), warn_only=True):
    if local('test -d %s' % _expand_path(destination), shell='/bin/bash').succeeded:
      sep = "" if destination.endswith('/') else "/"
      destination += sep + os.path.basename(filename)

  # Process template
  text = None
  if use_jinja:
    try:
      template_dir = template_dir or os.getcwd()
      template_dir = apply_lcwd(template_dir, env)
      from jinja2 import Environment, FileSystemLoader
      jenv = Environment(loader=FileSystemLoader(template_dir))
      text = jenv.get_template(filename).render(**context or {})
      text = text.encode('utf-8')
    except ImportError:
      import traceback
      tb = traceback.format_exc()
      abort(tb + "\nUnable to import Jinja2 -- see above.")
  else:
    filename = apply_lcwd(filename, env)
    with open(os.path.expanduser(filename)) as inputfile:
      text = inputfile.read()
    if context:
      text = text % context

  # Back up original file
  print destination, os.path.isfile(destination)
  if backup and os.path.isfile(destination):
    local("cp %s{,.bak}" % _expand_path(destination), shell='/bin/bash')

  # Write in file.
  with open(destination, 'w') as f:
    f.write(text)
    f.close()

def inject_zkclient_and_config():
  """
  Simple decorator to inject zookeeper client and config into the wrapped function.
  The wrapped function should have the following arguments:
    - zklist     : (required) comma-seperated list of the ZooKeeper servers
    - configfile : (optional) config filename
    - context    : (injected) context
        zkclient   - zookeeper client wrapper for Arcus
        config     - map for configuration
        zklist     - zookeeper list -> (ip, port)
        mclist     - memcached list -> (ip, port, config)
        ipset      - set of IPs for all servers (zookeeper+memcached)

  For example,

    @task
    @inject_zkclient_and_config()
    def mytask(zklist, configfile=None, context=None):
      pass
  """
  TaskContext = namedtuple('TaskContext', ['zkclient', 'config', 'zklist', 'mclist', 'ipset', 'zkport'])
  ZkContext = namedtuple('ZkContext', ['ip', 'port'])
  McContext = namedtuple('McContext', ['ip', 'port', 'config'])

  def actualDecorator(f):
    @wraps(f)
    def wrapped(*args, **kargs):
      """
      kargs.zklist : zookeeper list
      kargs.configfile : config filename
      """
      # before

      # we need zklist
      if kargs.get('zklist') is None:
        raise Exception('You should pass comma-seperated ZooKeeper list')

      # if we already have context parameter, just pass it
      if kargs.get('context') is not None:
        return f(**kargs)

      zklist = kargs.get('zklist')
      configfile = kargs.get('configfile')
      service_code = kargs.get('service_code')
      zkclient = ArcusZooKeeper(zklist, 15000)
      config = None
      ctx_zklist = []
      ctx_mclist = []
      ctx_ipset = set([])
      fab_roledefs = {
        'zookeeper': [],
        'memcached': []
      }

      # context.zklist
      for zk in zklist.split(','):
        hostport = zk.split(':')
        if len(hostport) != 2:
          continue
        ctx_zklist.append(ZkContext(hostport[0], hostport[1]))
        ctx_ipset.add(hostport[0])
        fab_roledefs['zookeeper'].append(hostport[0])

      if configfile is not None:
        config = read_cluster_config(configfile)

        # context.mclist
        for server in config.get('servers', []):
          global_config = config.get('config', {})
          per_node_config = server.get('config', {})
          merged_config = dict(global_config.items() + per_node_config.items())

          ip = server.get('ip')
          port = merged_config.get('port')
          ctx_mclist.append(McContext(ip, port, merged_config))
          ctx_ipset.add(ip)
          fab_roledefs['memcached'].append(ip)

      zkport = ctx_zklist[0].port # FIXME
      context = TaskContext(zkclient, config, ctx_zklist, ctx_mclist, ctx_ipset, zkport)

      # update fabric env
      env.roledefs.update(fab_roledefs)

      # run the task
      r = f(context=context, **kargs)
      
      return r
    return wrapped
  return actualDecorator

def read_cluster_config(config_file):
  with open(config_file, 'r') as fp:
    result = json.load(fp)
    fp.close()
    return result

#-----------
# Initialize
#-----------

@inject_zkclient_and_config()
def initialize(zklist, configfile=None, context=None):
  env.context = context
  print 'Server Roles'
  print '\t{0}\n'.format(env.roledefs)

if env.get('zklist') is None:
  env['zklist'] = '127.0.0.1:2181'
  #raise Exception('Missing zklist: --set zklist="<comma-seperated zookeeper list>"')

# initialize global context
initialize(zklist=env.get('zklist'), configfile=env.get('config'))

#-------------
# Deploy Tasks
#-------------

@task
@roles('zookeeper', 'memcached')
@parallel
def deploy():
  """ Deploy current Arcus directory in every nodes. Note that existing directories will be deleted. """
  # get package directory
  ssh_package_path = os.path.normpath(os.path.join(env.ARCUS_PATH, os.path.pardir))

  if is_localhost():
    print green('skipping localhost')
  else:
    run('mkdir -p {0}'.format(ssh_package_path))
    upload_project(local_dir=env.ARCUS_PATH, remote_dir=ssh_package_path)

@task
@roles('zookeeper', 'memcached')
def rsync():
  """ Rsync current Arcus directory (except zookeeper directory) to every nodes. """
  # get package directory
  ssh_package_path = os.path.normpath(os.path.join(env.ARCUS_PATH, os.path.pardir))

  if is_localhost():
    print green('skipping localhost')
  else:
    run('mkdir -p {0}'.format(ssh_package_path))
    rsync_project(local_dir=env.ARCUS_PATH, remote_dir=ssh_package_path, exclude=['zookeeper'])

#--------------------
# Tasks for ZooKeeper
#--------------------

@task
def zk_config():
  """ Make and distribute ZooKeeper configurations. """
  myid = 0
  for host in env.roledefs['zookeeper']:
    myid += 1
    #execute(zk_config_id, iplist, context.zkport, myid, hosts=[host])
    execute(zk_config_id, env.roledefs['zookeeper'], env.context.zkport, myid, hosts=[host])

@task
@roles('zookeeper')
def zk_start():
  """ Start ZooKeeper servers. """
  run_or_local('bin/zkServer.sh start', cd=env.ZOOKEEPER_PATH)

@task
@roles('zookeeper')
def zk_stop():
  """ Stop ZooKeeper servers. """
  run_or_local('bin/zkServer.sh stop', cd=env.ZOOKEEPER_PATH)

@task
@roles('zookeeper')
def zk_restart():
  """ Restart ZooKeeper servers. """
  run_or_local('bin/zkServer.sh restart', cd=env.ZOOKEEPER_PATH)

@task
@roles('zookeeper')
def zk_stat():
  """ Get ZooKeeper stat for all. """
  run_or_local('echo stat | nc localhost {0}'.format(env.context.zkport), warn_only=False)

@task
def zk_create_arcus_structure():
  """ Initialize Arcus structures in ZooKeeper. """
  env.context.zkclient.start()
  env.context.zkclient.init_structure()
  for s in env.context.zkclient.get_structure():
    print '/arcus/' + s
  env.context.zkclient.stop()

@task
def zk_delete_arcus_structure():
  """ Delete Arcus structures in ZooKeeper. """
  input = prompt(
    red('!!Caution!!\n') +
    'This will delete the Arcus directories in ZooKeeper permanently.\nPlease type in the following texts to confirm: ' +
    '"' + red('Delete the Arcus') + '"\n' +
    '>> '
  )
  if 'Delete the Arcus' == input:
    env.context.zkclient.start()
    env.context.zkclient.drop_structure()
    env.context.zkclient.stop()
  else:
    print 'Delete canceled.'

@task
def zk_init():
  """ Initialize ZooKeeper. """
  print cyan('====== Task: zk_config')
  execute(zk_config)
  print cyan('====== Task: zk_start')
  execute(zk_start)
  print cyan('====== Func: zk_wait')
  zk_wait(env.context.zkport)
  print cyan('====== Task: zk_create_arcus_structure')
  execute(zk_create_arcus_structure)
  print cyan('====== Task: zk_stop')
  execute(zk_stop)

def zk_config_id(iplist, clientport, myid):
  if is_localhost():
    run_or_local("mkdir -p data", cd=env.ZOOKEEPER_PATH)
    run_or_local("echo {0} > data/myid".format(myid), cd=env.ZOOKEEPER_PATH)
    context = { 'port': clientport, 'hosts': iplist, 'path': env.ZOOKEEPER_PATH }
    upload_template_local(filename='zoo.cfg', destination=env.ZOOKEEPER_PATH+'/conf/', template_dir=env.TEMPLATE_PATH, context=context, use_jinja=True)
  else:
    with cd(env.ZOOKEEPER_PATH):
      run("mkdir -p data")
      run("echo {0} > data/myid".format(myid))
      context = { 'port': clientport, 'hosts': iplist, 'path': env.ZOOKEEPER_PATH }
      upload_template(filename='zoo.cfg', destination='conf/', template_dir=env.TEMPLATE_PATH, context=context, use_jinja=True)

def zk_wait(clientport):
  """ Wait for ZooKeeper to come up and elect a leader. """
  sleep_seconds = 3
  cmd = 'GOT=$(echo stat | nc localhost {0} | grep Mode:); if [ -z "$GOT" ]; then echo "Mode: stale"; else echo $GOT; fi'
  while True:
    complete = False
    has_stale = False
    for host in env.roledefs['zookeeper']:
      mode = ''
      if is_localhost(host):
        mode = local(cmd.format(clientport), capture=True, shell='/bin/bash')
      else:
        with settings(host_string=host):
          mode = run(cmd.format(clientport), warn_only=True)
      if 'Mode: leader' in mode or 'Mode: standalone' in mode:
        complete = True
      if 'Mode: stale' in mode:
        has_stale = True
      #if not ('Mode: standalone' in mode or 'Mode: follower' in mode or 'Mode: leader' in mode or 'Mode: stale' in mode):
      #  complete = False
      #  break
    if complete:
      if has_stale:
        print green('got a leader, but some nodes are out of order')
      else:
        print green('got a leader, and all nodes are up')
      return
    else:
      print red('zookeeper cluster not complete yet; sleeping {0} seconds'.format(sleep_seconds))
      time.sleep(sleep_seconds)

#------------
# Arcus Tasks
#------------

@task
def mc_register():
  """ Add or update an Arcus cluster. """
  if env.context.config is None:
    print red('env.config required: fab --set:config="..."')
    sys.exit(0)

  env.context.zkclient.start()
  env.context.zkclient.update_service_code(env.context.config)
  env.context.zkclient.stop()

@task
def mc_unregister(service_code):
  """ Delete an Arcus cluster. """
  confirm = 'Delete ' + service_code

  input = prompt(
    red('!!Caution!!\n') +
    'This will delete an Arcus cluster permanently.\nPlease type in the following texts to confirm: ' +
    '"' + red(confirm) + '"\n' +
    '>> '
  )
  if confirm == input:
    env.context.zkclient.start()
    cluster, cluster_raw, stat = env.context.zkclient.get_config_for_service(service_code)
    env.context.zkclient.delete_service_code(cluster)
    env.context.zkclient.stop()
  else:
    print 'Delete canceled.'
  
@task
def mc_start(service_code):
  """ Start an Arcus cluster. """
  env.context.zkclient.start()
  cluster, cluster_raw, stat = env.context.zkclient.get_config_for_service(service_code)

  for server in cluster['servers']:
    config = merge_map(cluster.get('config'), server.get('config'))

    if len(config) == 0:
      print red('Skipping {0}: config not found'.format(server))
      continue

    zkhosts = ",".join([ each.ip + ':' + each.port for each in env.context.zklist ])
    execute(mc_start_server, config, zkhosts, hosts=[server['ip']])
  
  env.context.zkclient.stop()

@task
def mc_stop(service_code):
  """ Stop an Arcus cluster. """
  env.context.zkclient.start()
  cluster, cluster_raw, stat = env.context.zkclient.get_config_for_service(service_code)

  for server in cluster['servers']:
    config = merge_map(cluster.get('config'), server.get('config'))

    if len(config) == 0:
      print red('Skipping {0}: config not found'.format(server))
      continue

    execute(mc_stop_server, config, hosts=[server['ip']])
  
  env.context.zkclient.stop()

@task
def mc_list(service_code=None):
  """ List all or single Arcus cluster. """
  env.context.zkclient.start()

  if service_code is None:
    # list all cluster
    all = env.context.zkclient.list_all_service_code()
    if all is not None:
      mc_list_print(all)
  else:
    # list a cluster
    each = env.context.zkclient.list_service_code(service_code)
    if each is not None:
      mc_list_print([ each ])
      mc_list_print_detail(each) 

  env.context.zkclient.stop()

def merge_map(map1, map2):
  if map1 == None:
    map1 = {}
  if map2 == None:
    map2 = {}
  return dict(map1.items() + map2.items())

def mc_list_print(all):
  data = []
  for each in all:
    nonline = len(each['online'])
    noffline = len(each['offline'])
    nundefined = len(each['undefined'])
    ntotal = nonline + noffline
    status = 'OK'
    if noffline + nundefined == ntotal:
      status = 'DOWN'
    elif noffline > 0 or nundefined > 0:
      status = 'SOME_DOWN'
    data.append({
      'serviceCode': each['serviceCode'],
      'total': ntotal,
      'online': nonline,
      'offline': noffline,
      'created': each.get('created'),
      'modified': each.get('modified'),
      'status': status
    })

  headers = ['serviceCode', 'status', 'total', 'online', 'offline', 'created', 'modified']
  pptable(data, headers=headers)

def mc_list_print_detail(each):
  if len(each['online']) > 0:
    print '\nOnline'
    for o in each['online']:
      print green('\t{0}'.format(o))
  if len(each['offline']) > 0:
    print '\nOffline'
    for o in each['offline']:
      print red('\t{0}'.format(o))
  if len(each['undefined']) > 0:
    print '\nUndefined'
    for o in each['undefined']:
      print red('\t{0}'.format(o))

def mc_start_server(config, zkhosts):
  exe = '%s/bin/memcached -E %s/lib/default_engine.so -X %s/lib/syslog_logger.so -X %s/lib/ascii_scrub.so -d -v -r -R5 -U 0 -D: -b 8192 -m%s -p %s -c %s -t %s -z %s'%(
          ARCUS_PATH, ARCUS_PATH, ARCUS_PATH, ARCUS_PATH,
          config['memlimit'], config['port'], config['connections'], config['threads'], zkhosts
        )
  try:
    # memcached process would be blocked (I don't know why..) so just timeout it
    run_or_local(exe, warn_only=True, timeout=2)
  except Exception as e:
    print e
    pass

def mc_stop_server(config):
  exe = "ps -ef | grep -e memcached | grep -e '-p %s' | grep -v 'ssh' | awk '{print $2}'"%config['port']
  procnum = run_or_local(exe, timeout=2, capture=True)
  if procnum is not None and procnum != '':
    run_or_local('kill -INT %s'%procnum)

#--------------
# Utility Tasks 
#--------------

@task
def quicksetup():
  """
  Quicksetup
  """
  service_code = env.context.config.get('serviceCode')
  if service_code is None:
    print red('service code is required in configfile')
    sys.exit(0)

  print cyan('====== Task: deploy')
  execute(deploy)
  print cyan('====== Task: zk_config')
  execute(zk_config)
  print cyan('====== Task: zk_start')
  execute(zk_start)
  print cyan('====== Func: zk_wait')
  zk_wait(env.context.zkport)
  print cyan('====== Task: zk_create_arcus_structure')
  execute(zk_create_arcus_structure)
  print cyan('====== Task: mc_register')
  execute(mc_register)
  print cyan('====== Task: mc_start')
  execute(mc_start, service_code)
  time.sleep(1)
  print cyan('====== Task: mc_list')
  execute(mc_list, service_code)

@task
def ping(service_code):
  """ Run 'ping' on all hosts """
  print cyan('====== Ping to ZooKeeper servers')
  for host in env.roledefs['zookeeper']:
    local("ping -c 3 {0}".format(host))

  env.context.zkclient.start()
  cluster, cluster_raw, stat = env.context.zkclient.get_config_for_service(service_code)
  env.context.zkclient.stop()

  print ''
  print cyan('====== Ping to Memcached servers')
  memcached_servers = set([ each['ip'] for each in cluster['servers'] ])
  for each in memcached_servers:
    local("ping -c 3 {0}".format(each))
    
"""
@task
@roles('zookeeper', 'memcached')
def ssh_key_copy(ssh_pub_key = "~/.ssh/id_rsa.pub"):
  ssh_pub_key_path = os.path.expanduser(ssh_pub_key)
  remote = 'arcus-fabric-key.pem'
  put(ssh_pub_key_path, remote)
  run('mkdir -p ~/.ssh')
  run('cat {0} >> ~/.ssh/authorized_keys'.format(remote))
  run('rm {0}'.format(remote))
"""

