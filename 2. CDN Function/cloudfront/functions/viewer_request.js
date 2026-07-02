import cf from 'cloudfront';

const kvs = cf.kvs();

async function handler(event) {
    const request = event.request;
    const cookies = request.cookies;

    let version;
    let assigned = false;

    if (cookies['x-sp-ab'] && cookies['x-sp-ab'].value) {
        version = (cookies['x-sp-ab'].value === 'b') ? 'b' : 'a';
    } else {
        const weightStr = await kvs.get('weight');
        const weight = parseFloat(weightStr);
        version = (Math.random() < weight) ? 'b' : 'a';
        assigned = true;
    }

    const key = (version === 'b') ? 'version_b' : 'version_a';
    const uri = await kvs.get(key);
    request.uri = uri;

    if (assigned) {
        request.headers['x-sp-ab-assigned'] = { value: version };
    }

    return request;
}