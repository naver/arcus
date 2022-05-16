#!/usr/bin/env python
# -*- coding: utf-8 -*-

# FIXME Add Arcus's python lib directory to PYTHONPATH
import sys
import os
import site
import datetime
import traceback

#ARCUS_PATH = os.path.normpath(os.path.dirname(os.path.realpath(__file__)) + '/../..')
#ARCUS_SITE = os.path.join(ARCUS_PATH, 'lib/python/site-packages')
#site.addsitedir(ARCUS_SITE)

import json
from optparse import OptionParser
from kazoo.client import KazooClient

class ArcusZooKeeper:
  """
  ZooKeeper helper for Arcus
  """

  def __init__(self, hostports, timeout):
    self.hostports = hostports
    self.timeout = timeout
    self.zk = KazooClient(hosts=hostports, read_only=False)

  def start(self):
    self.zk.start()

  def stop(self):
    self.zk.stop()

  def init_structure(self):
    if self.zk.exists('/arcus'):
      print('init_arcus_structure: fail (/arcus exists)')
      return False

    tx = self.zk.transaction()
    tx.create('/arcus', b'')
    tx.create('/arcus/cache_list', b'')
    tx.create('/arcus/client_list', b'')
    tx.create('/arcus/cache_server_mapping', b'')
    results = tx.commit()
    if len(results) > 0:
      print(results)
      return False

    print('init_structure: success')
    return True

  def drop_structure(self):
    self.zk.delete('/arcus', recursive=True)
    print('delete_structure: success')

  def get_structure(self):
    return self.zk.get_children('/arcus')

  def get_mapping_for_service(self, service_code):
    result = []
    cache_list = '/arcus/cache_list/%s'%service_code
    mapping = '/arcus/cache_server_mapping'

    all = self.zk.get_children(mapping)
    for ipport in all:
      codes = self.zk.get_children('%s/%s'%(mapping, ipport))
      if len(codes) > 0:
        if codes[0] == service_code:
          result.append('%s/%s'%(mapping, ipport))

    return result

  def get_config_for_service(self, service_code):
    cache_list = '/arcus/cache_list/%s'%service_code
    data, stat = self.zk.get(cache_list)
    return json.loads(data), data, stat

  def update_service_code(self, cluster):
    cache_list = '/arcus/cache_list/%s'%cluster['serviceCode']
    client_list = '/arcus/client_list/%s'%cluster['serviceCode']
    mapping = '/arcus/cache_server_mapping'

    try:
      delete_list = self.get_mapping_for_service(cluster['serviceCode'])

      # 0. Create a transaction
      tx = self.zk.transaction()

      # 1. Cache list
      if self.zk.exists(cache_list):
        c1, c2, c3 = self.get_config_for_service(cluster['serviceCode'])
        cluster['created'] = c1.get('created')
        cluster['modified'] = str(datetime.datetime.now())
        tx.set_data(cache_list, json.dumps(cluster))
      else:
        cluster['created'] = str(datetime.datetime.now())
        tx.create('/arcus/cache_list/%s'%cluster['serviceCode'], json.dumps(cluster))

      # 2. Client list
      if self.zk.exists(client_list):
        pass
      else:
        tx.create('/arcus/client_list/%s'%cluster['serviceCode'], b'')

      # 3. Mapping
      for each in delete_list:
        tx.delete('%s/%s'%(each, cluster['serviceCode']))
        tx.delete(each)

      for server in cluster['servers']:
        global_config = cluster.get('config', {})
        per_node_config = server.get('config', {})
        config = dict(global_config.items() + per_node_config.items())

        if len(config) == 0:
          print('update_service_code: config not found for {0}'.format(server))
          continue

        map_ip = '/arcus/cache_server_mapping/%s:%s'%(server['ip'], config['port'])
        map_code = '%s/%s'%(map_ip, cluster['serviceCode'])

        tx.create(map_ip, json.dumps(config))
        tx.create(map_code, b'')

      # 4. Commit
      results = tx.commit()
      print(results)
    except Exception as e:
      traceback.print_exc()
      
  def delete_service_code(self, cluster):
    cache_list = '/arcus/cache_list/%s'%cluster['serviceCode']
    client_list = '/arcus/client_list/%s'%cluster['serviceCode']
    mapping = '/arcus/cache_server_mapping'

    try:
      delete_list = self.get_mapping_for_service(cluster['serviceCode'])

      # 0. Create a transaction
      tx = self.zk.transaction()

      # 1. Cache list
      tx.delete('/arcus/cache_list/%s'%cluster['serviceCode'])

      # 2. Client list
      tx.delete('/arcus/client_list/%s'%cluster['serviceCode'])

      # 3. Mapping
      for each in delete_list:
        tx.delete('%s/%s'%(each, cluster['serviceCode']))
        tx.delete(each)

      # 4. Commit
      results = tx.commit()
      print(results)
    except Exception as e:
      traceback.print_exc()

  def list_all_service_code(self):
    result = []
    cache_list = '/arcus/cache_list'
    
    try:
      list = self.zk.get_children(cache_list)
      for each in list:
        result.append(self.list_service_code(each))
      return result
    except Exception as e:
      traceback.print_exc()

  def list_service_code(self, service_code):
    result = {}
    cache_list = '/arcus/cache_list/%s'%service_code
    client_list = '/arcus/client_list/%s'%service_code
    mapping = '/arcus/cache_server_mapping'

    try:
      data, stat = self.zk.get(cache_list)
      static_list = self.get_mapping_for_service(service_code)
      current_list = self.zk.get_children(cache_list)

      # sort the lists
      static_list.sort()
      current_list.sort()

      # get clusterConfig
      cluster = json.loads(data)

      # get clusterStatus
      static_set = set([ each.split('/')[-1] for each in static_list ])
      current_set = set([ each.split('-')[0] for each in current_list ])
      offline = static_set - current_set
      online = static_set - offline
      undefined = current_set - static_set

      result['serviceCode'] = service_code
      result['config'] = cluster
      result['online'] = list(online)
      result['offline'] = list(offline)
      result['undefined'] = list(undefined)
      result['created'] = cluster.get('created')
      result['modified'] = cluster.get('modified')
      return result

    except Exception as e:
      traceback.print_exc()


if __name__ == '__main__':
  pass
