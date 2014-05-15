# pptable is written by Mateusz Lapsa-Malawski under the MIT License.
# - https://github.com/munhitsu/pptable
# - http://blog.yjl.im/2014/04/pptable-pretty-print-list-of-dict-as.html

from __future__ import print_function


def pptable(data, headers=None, print_func=print):
    """
    prints data as a table assuming that data is a list of dictionaries (single level)
    if headers are provided then they specify sequence of columns

    example of data:

    >>> data = [
    ... {'slug': u'ams1', 'name': u'Amsterdam 1', 'region_id': 2},
    ... {'slug': u'sfo1', 'name': u'San Francisco 1', 'region_id': 3},
    ... {'slug': u'nyc2', 'name': u'New York 2', 'region_id': 4},
    ... {'slug': u'ams2', 'name': u'Amsterdam 2', 'region_id': 5},
    ... {'slug': u'sgp1', 'name': u'Singapore 1', 'region_id': 6}]

    example output:

    >>> pptable(data)
    ----------------------------------
    region_id  name             slug
    ----------------------------------
            2  Amsterdam 1      ams1
            3  San Francisco 1  sfo1
            4  New York 2       nyc2
            5  Amsterdam 2      ams2
            6  Singapore 1      sgp1

    example of headers:

    >>> header = ['slug', 'name']
    >>> pptable(data, header) #doctest: +NORMALIZE_WHITESPACE
    -----------------------
    slug  name
    -----------------------
    ams1  Amsterdam 1
    sfo1  San Francisco 1
    nyc2  New York 2
    ams2  Amsterdam 2
    sgp1  Singapore 1

    """
    keys = set()
    formatting = dict()

    if not data:
        return

    def update_dict_with_max(dictionary, key, value):
        if key in dictionary:
            dictionary[key] = max(current_len, dictionary[key])
        else:
            dictionary[key] = current_len

    for line in data:
        keys.update(line.keys())
        for key, value in getattr(line, 'iteritems', line.items)():
            current_len = len("{0}".format(value))
            update_dict_with_max(formatting, key, current_len)

    for key in keys:
        current_len = len("{0}".format(key))
        update_dict_with_max(formatting, key, current_len)

    if not headers:
        headers = keys

    #formatting_string = "  ".join(map(lambda header: "{{0}{:{1}}}".format(i, formatting[header]), headers))
    formatting_string = "  ".join([ "{{{0}:{1}}}".format(i, formatting[header]) for i, header in enumerate(headers) ])

    line_len = sum([formatting[header] for header in headers]) + len(headers)*2
    print_func("-"*line_len)
    print_func(formatting_string.format(*headers))
    print_func("-"*line_len)
    for line in data:
        values = []
        for header in headers:
            if header in line:
                values.append(line[header])
            else:
                values.append('')

        print_func(formatting_string.format(*values))
