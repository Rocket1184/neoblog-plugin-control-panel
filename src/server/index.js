'use strict';

const Body = require('koa-body');
const KoaJwt = require('koa-jwt');
const Jwt = require('jsonwebtoken');
const Router = require('koa-router');

const router = new Router();

const secret = 'shared-secret-uuid-2f33e70d-b258-46e3-9e14-129438ee329e';

router.use(Body());

router.post('/control/api/token', ctx => {
    const { usr, pwd } = ctx.request.body;
    if (usr === 'root' && pwd === 'root') {
        const profile = {
            id: 0,
            username: 'root',
            groups: ['root']
        };
        const token = Jwt.sign(profile, secret, { expiresIn: '24h' });
        ctx.response.body = { token };
        return;
    }
    ctx.status = 403;
});

router.use(KoaJwt({ secret }));

router.get('/control/api/sysinfo', ctx => {
    ctx.body = process.versions;
});

router.get('/control/api/profile', ctx => {
    ctx.body = ctx.state.user;
});

module.exports = {
    routes: router.routes()
};
