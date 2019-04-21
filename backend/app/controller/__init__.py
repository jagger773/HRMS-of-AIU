def call(controller_name, bag):
    if hasattr(controller_name, '__call__'):
        return controller_name(bag)
    module = controller_name.split('.')
    m = __import__('controller.' + module[0])
    m = getattr(m, module[0])
    m = getattr(m, module[1])
    return m(bag)
