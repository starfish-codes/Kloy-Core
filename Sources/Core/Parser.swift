import Foundation
struct Parser<A> {
    let parse: (_ str: inout Substring) ->  A?
    
    func parse(_ str:String) -> (match: A?, rest:Substring){
        var str = str[...]
        let match = self.parse(&str)
        return (match, str)
    }

    func map<B>(_ f: @escaping (A)-> B) -> Parser<B> {
        return Parser<B> { str in
          self.parse(&str).map(f)
        }
    }
    
    
}

func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
  return Parser<(A, B)> { str in
    let original = str
    guard let matchA = a.parse(&str) else { return nil }
    guard let matchB = b.parse(&str) else {
      str = original
      return nil
    }
    return (matchA, matchB)
  }
}






func literal(_ literal: String ) -> Parser<Void> {
    return Parser<Void> { str in
        guard str.hasPrefix(literal) else { return nil }
        str.removeFirst(literal.count)
        
        return ()
    }
}

extension Parser where A == String{
    
    
    
}

struct Parsers {
    //This will get the UUID interpretation of the query its value
    static func queryUUID(queryName: String) -> Parser<UUID> {
        return Parser<UUID>{ str in
            guard let array = convertQueryParamsIntoArray(in: str) else {return nil}
            guard var found = array.first(where: {$0.starts(with: queryName)}) else {return nil}
            guard (literal("\(queryName)=").parse(&found) != nil) else {return nil}
            
            guard let match =  UUID(String(found)) else {return nil}
            //Mutate the str so that found is removed from it
            str = array.filter({!$0.starts(with: "\(queryName)=\(found)")}).reduce("", {$0 + "&" + $1})
            return match
        }
    }
    static let urlParser = Parser<String> { url in
        var prefix = url.prefix(while: {$0 != "?"})
        prefix.append(contentsOf: "?") //The ? also belongs to the prefix
        //Maybe some validation if it is indeed a url -> starts with http 👈 not so sure about this
        //if !prefix.starts(with: "http") {return nil}
        url.removeFirst(prefix.count)
        return String(prefix) //This could be optimised
    }
    
    //This will get the String interpretation of the query its value
    static func queryString(queryName: String) -> Parser<String> {
        return Parser<String>{ str in
            guard let array = convertQueryParamsIntoArray(in: str) else {return nil}
            guard var found = array.first(where: {$0.starts(with: queryName)}) else {return nil}

            guard (literal("\(queryName)=").parse(&found) != nil) else {return nil}
            
            //Mutate the str so that found is removed from it
            str = array.filter({!$0.starts(with: "\(queryName)=\(found)")}).reduce("", {$0 + "&" + $1})
            return String(found)
        }
    }

    private static func convertQueryParamsIntoArray(in str:Substring) -> Array<Substring>? {
        let queries = str.split(separator: "&")
        if queries.count == 0 {return nil}
        return queries
    }
}
