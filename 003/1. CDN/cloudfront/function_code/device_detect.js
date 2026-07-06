function handler(event) {
    var request = event.request;
    var headers = request.headers;
    var qs = request.querystring;

    if (Object.keys(qs).length > 0) {
        return request;
    }

    var isMobile = false;

    if (headers['cloudfront-is-mobile-viewer'] &&
        headers['cloudfront-is-mobile-viewer'].value === 'true') {
        isMobile = true;
    } else if (headers['cloudfront-is-desktop-viewer'] &&
               headers['cloudfront-is-desktop-viewer'].value === 'true') {
        isMobile = false;
    } else if (headers['user-agent']) {
        // 2) User-Agent 폴백
        var ua = headers['user-agent'].value.toLowerCase();
        if (/mobile|iphone|ipod|android.*mobile|windows phone|blackberry/i.test(ua)) {
            isMobile = true;
        }
    }

    if (isMobile) {
        request.querystring = {
            w:    { value: '480' },
            h:    { value: '320' },
            type: { value: 'mobile' }
        };
    } else {
        request.querystring = {
            w:    { value: '1920' },
            h:    { value: '1080' },
            type: { value: 'desktop' }
        };
    }

    return request;
}