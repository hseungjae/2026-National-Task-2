function handler(event) {
    const request = event.request;
    const response = event.response;

    const assigned = request.headers['x-sp-ab-assigned'];
    if (assigned && assigned.value) {
        response.cookies['x-sp-ab'] = {
            value: assigned.value,
            attributes: 'Path=/; Max-Age=86400'
        };
    }

    return response;
}
