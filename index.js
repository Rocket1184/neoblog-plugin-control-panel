'use strict';

const path = require('path');
const crypto = require('crypto');
const Send = require('koa-send');
const Mount = require('koa-mount');
const Router = require('koa-router');
const Static = require('koa-static-cache');

const jwtSecret = crypto.randomFillSync(Buffer.alloc(512)).toString('hex');
const ApiRouter = require('./src/server/api-router');
const apiRouter = new ApiRouter(jwtSecret);

const staticDir = path.join(__dirname, 'static');
const router = new Router();

router.get('/control/panel', async ctx => {
    await Send(ctx, 'index.html', { root: staticDir });
});

const staticRoutes = Mount('/control', Static(staticDir, { maxAge: 30 * 24 * 3600 }));

const apiRoutes = Mount('/control/api', apiRouter.routes);

module.exports = {
    name: 'neoblog-plugin-control-panel',
    version: '0.1.0',
    description: 'article/config management panel for neoblog.',
    author: 'rocka <i@rocka.me>',
    routes: [router.routes(), staticRoutes, apiRoutes],
};
