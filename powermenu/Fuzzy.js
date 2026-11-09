.pragma library

function score(str, query) {
    if (!query || query === "") return 1
    if (!str) return 0
    var s = String(str).toLowerCase()
    var q = String(query).toLowerCase()
    if (s === q) return 1000
    if (s.startsWith(q)) return 800
    if (s.indexOf(" " + q) >= 0 || s.indexOf("-" + q) >= 0) return 600
    if (s.indexOf(q) >= 0) return 400
    var i = 0
    for (var j = 0; j < s.length && i < q.length; j++)
        if (s[j] === q[i]) i++
    return i === q.length ? 100 : 0
}
