let uri = "/api/v1/test/10"
print(uri.split(separator: "/"))

let route = [3, 2, 4, 2]

let combi = zip(uri.split(separator: "/"), route)

let result = combi
    .map { $0.count == $1 }
    .reduce(true, { $0 && $1 })
print(result)
