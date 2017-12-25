'use strict';

const fs = require('fs');
const path = require('path');
const util = require('util');
const Body = require('koa-body');
const KoaJwt = require('koa-jwt');
const Jwt = require('jsonwebtoken');
const Router = require('koa-router');

const access = util.promisify(fs.access);
const unlink = util.promisify(fs.unlink);
const writeFile = util.promisify(fs.writeFile);

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
            ctx.status = 401;
        });

        this.router.use(KoaJwt({ secret: this.secret }));

        this.router.get('/sysinfo', ctx => {
            ctx.body = process.versions;
        });

        this.router.get('/profile', ctx => {
            ctx.body = ctx.state.user;
        });

        this.router.get('/articles', ctx => {
            let { offset, limit } = ctx.query;
            offset = offset || 0;
            limit = limit || 10;
            console.log(offset, limit);
            ctx.body = ctx.app.server.state.articles
                .slice(offset, offset + limit)
                .map(a => ({ meta: a.meta, file: a.file }));
        });

        this.router.use('/articles/:name', async (ctx, next) => {
            ctx.state.article = ctx.app.server.state.articles
                .filter(a => a.file.base === ctx.params.name)
                .pop();
            try {
                await next();
            } catch (err) {
                if (err.code === 'ENOENT') {
                    return ctx.status = 404;
                } else if (err.code === 'EACCES') {
                    return ctx.status = 403;
                }
                ctx.body = err.stack;
                ctx.status = 500;
            }
        })

        // create new article
        this.router.post('/articles/:name', async ctx => {
            const { article } = ctx.state;
            if (article) {
                ctx.status = 409;
                ctx.body = {
                    message: `file named ${article.file.base}.${article.file.base} already exists.`
                };
            } else {
                const { type, src } = ctx.request.body;
                await writeFile(path.join(ctx.app.server.config.articleDir, `${ctx.params.name}.${type}`), src);
                return ctx.status = 200;
            }
        });

        // update article
        this.router.put('/articles/:name', async ctx => {
            const { article } = ctx.state;
            if (article) {
                await access(article.file.path, fs.constants.W_OK);
                await unlink(article.file.path);
                const { type, src } = ctx.request.body;
                await writeFile(path.join(ctx.app.server.config.articleDir, `${ctx.params.name}.${type}`), src);
                return ctx.status = 200;
            } else {
                return ctx.status = 404;
            }
        });

        this.router.delete('/articles/:name', async ctx => {
            const { article } = ctx.state;
            if (article) {
                await access(article.file.path, fs.constants.W_OK);
                await unlink(article.file.path);
                return ctx.status = 200;
            }
            ctx.status = 404;
        });
    }

    get routes() {
        return this.router.routes();
    }
}

module.exports = ApiRouter;
