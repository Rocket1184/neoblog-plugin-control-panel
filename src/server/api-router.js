'use strict';

const Body = require('koa-body');
const KoaJwt = require('koa-jwt');
const Jwt = require('jsonwebtoken');
const Router = require('koa-router');

class ApiRouter {
    constructor(secret, jwtOptions) {
        if (!secret) throw new Error('[ApiRoutes] `secret` must be specificed.');
        this.secret = secret;
        if (!jwtOptions) this.jwtOptions = { expiresIn: '2d' };
        else this.jwtOptions = { ...jwtOptions };
        this.__init();
    }

    __init() {
        this.router = new Router();
        this.router.use(Body());

        this.router.post('/token', ctx => {
            const { usr, pwd } = ctx.request.body;
            if (usr === 'root' && pwd === 'root') {
                const profile = {
                    id: 0,
                    username: 'root',
                    groups: ['root']
                };
                const token = Jwt.sign(profile, this.secret, this.jwtOptions);
                ctx.response.body = { token };
                return;
            }
            ctx.status = 403;
        });

        this.router.use(KoaJwt({ secret: this.secret }));

        this.router.get('/sysinfo', ctx => {
            ctx.body = process.versions;
        });

        this.router.get('/profile', ctx => {
            ctx.body = ctx.state.user;
        });
    }

    get routes() {
        return this.router.routes();
    }
}

module.exports = ApiRouter;
