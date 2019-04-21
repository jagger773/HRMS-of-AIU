angular.module 'stock'
.filter 'fileSize', ->
    sizes = [
        [1, 'b']
        [1024, 'Kb']
        [1024*1024, 'Mb']
        [1024*1024*1024, 'Gb']
    ]
    return (input) ->
        input = input || 0
        out = ''
        for size in sizes
            if input < size[0] and l_size
                out = (input / l_size[0]).toFixed(2) + ' ' + l_size[1]
            else
                l_size = size
        return out
