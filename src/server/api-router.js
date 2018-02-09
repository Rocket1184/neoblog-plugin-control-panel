'use strict';

const fs = require('fs');
const path = require('path');
const util = require('util');
const crypto = require('crypto');

const Body = require('koa-body');
const KoaJwt = require('koa-jwt');
const Jwt = require('jsonwebtoken');
const Router = require('koa-router');

const access = util.promisify(fs.access);
const rename = util.promisify(fs.rename);
const unlink = util.promisify(fs.unlink);
const writeFile = util.promisify(fs.writeFile);

class ApiRouter {
    constructor(secret, jwtOptions, usr, pwd, profile = {}) {
        if (!secret) throw new Error('[ApiRoutes] `secret` must be specificed.');
        this.secret = secret;
        if (!usr) throw new Error('[ApiRoutes] `usr` must be specificed.');
        this.usr = usr;
        if (!pwd) throw new Error('[ApiRoutes] `pwd` must be specificed.');
        this.pwd = crypto.createHash('sha384').update(pwd).digest('hex');
        this.profile = Object.assign(profile, { usr: this.usr });
        if (!jwtOptions) this.jwtOptions = { expiresIn: '2d' };
        else this.jwtOptions = { ...jwtOptions };
        this.__init();
    }

    __init() {
        this.router = new Router();
        this.router.use(Body());

        this.router.post('/token', ctx => {
            const { usr, pwd } = ctx.request.body;
            if (usr === this.usr && pwd === this.pwd) {
                const profile = this.profile;
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

        // get article source types which parser can understand
        this.router.get('/parser-types', async ctx => {
            ctx.body = ctx.app.server.parser.eventNames();
        });

        this.router.get('/articles', ctx => {
            const articles = ctx.app.server.state.articles;
            let { offset, limit } = ctx.query;
            offset = offset || 0;
            limit = limit || 10;
            const body = {
                total: articles.length,
                aritcles: articles
                    .slice(offset, offset + limit)
                    .map(a => ({ meta: a.meta, file: a.file }))
            };
            ctx.body = body;
        });

        this.router.use('/articles/:name', async (ctx, next) => {
            const article = ctx.app.server.state.articles.find(a => a.file.base === ctx.params.name);
            if (article) {
                ctx.state.article = article;
                ctx.state.fileName = `${article.file.base}.${article.file.ext}`
            }
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
        });

        // get single article detail
        this.router.get('/articles/:name', async ctx => {
            const { article } = ctx.state;
            ctx.body = article;
        });

        // create new article
        this.router.post('/articles/:name', async ctx => {
            const { article, fileName } = ctx.state;
            if (article) {
                ctx.status = 409;
                ctx.body = {
                    message: `file named '${fileName}' already exists.`
                };
            } else if (ctx.get('content-type') !== 'application/json') {
                ctx.status = 415;
                ctx.body = {
                    message: `please use 'Content-Type: application/json' and POST JSON string to me.`
                };
            } else {
                const { type, src } = ctx.request.body;
                const newName = `${ctx.params.name}.${type}`;
                await writeFile(path.join(ctx.app.server.config.articleDir, newName), src);
                ctx.status = 200;
                ctx.body = {
                    message: `file named '${newName}' has been created successfully.`
                };
            }
        });

        // update article
        this.router.put('/articles/:name', async ctx => {
            const { article } = ctx.state;
            if (article) {
                await access(article.file.path, fs.constants.W_OK);
                await unlink(article.file.path);
                const { type, src } = ctx.request.body;
                const newName = `${ctx.params.name}.${type}`;
                await writeFile(path.join(ctx.app.server.config.articleDir, newName), src);
                ctx.status = 200;
                ctx.body = {
                    message: `file named '${newName}' has been updated successfully.`
                };
            } else {
                ctx.status = 404;
                ctx.body = {
                    message: `could not modify inexistent file named '${ctx.params.name}'.`
                };
            }
        });

        this.router.delete('/articles/:name', async ctx => {
            const { article, fileName } = ctx.state;
            if (article) {
                await access(article.file.path, fs.constants.W_OK);
                await unlink(article.file.path);
                ctx.status = 200;
                ctx.body = {
                    message: `file named '${fileName}' has been deleted successfully.`
                };
            } else {
                ctx.status = 404;
                ctx.body = {
                    message: `could not delete inexistent file named '${ctx.params.name}'.`
                };
            }
        });

        // Apply partial modifications to article file. Currently only 'rename'.
        this.router.patch('/articles/:name', async ctx => {
            const { article, fileName } = ctx.state;
            if (ctx.get('content-type') !== 'application/json') {
                ctx.status = 415;
                ctx.body = {
                    message: `please use 'Content-Type: application/json' and PATCH JSON string to me.`
                };
            } else if (article) {
                await access(article.file.path, fs.constants.W_OK);
                const { type, payload } = ctx.request.body;
                switch (type) {
                    // eslint-disable-next-line no-case-declarations
                    case 'rename':
                        if (typeof payload !== 'string') {
                            ctx.status = 400;
                            ctx.body = {
                                message: `'payload' of 'rename' must be string.`
                            };
                            return;
                        } else if (payload === "") {
                            ctx.status = 400;
                            ctx.body = {
                                message: `'payload' of 'rename' cannot be empty.`
                            };
                            return;
                        } else {
                            const newPath = path.format({
                                dir: path.dirname(article.file.path),
                                base: `${payload}.${article.file.ext}`
                            });
                            await rename(article.file.path, newPath);
                        }
                        break;
                    default:
                        ctx.status = 400;
                        ctx.body = {
                            message: `unknown action type '${type}'.`
                        };
                        return;
                }
                ctx.status = 200;
                ctx.body = {
                    message: `file named '${fileName}' has been updated successfully..`
                };
            } else {
                ctx.status = 404;
                ctx.body = {
                    message: `could not rename inexistent file named '${ctx.params.name}'.`
                };
            }
        });
    }

    get routes() {
        return this.router.routes();
    }
}

module.exports = ApiRouter;
