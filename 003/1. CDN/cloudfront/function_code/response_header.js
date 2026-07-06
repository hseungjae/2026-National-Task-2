function handler(event) {
    var request = event.request;
    var response = event.response;
    var qs = request.querystring;

    var deviceType = 'desktop';
    if (qs.type && qs.type.value) {
        deviceType = qs.type.value;
    }

    response.headers['x-device-type'] = { value: deviceType };
    response.headers['x-resized']     = { value: 'true' };

    return response;
}