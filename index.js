'use strict';

const path = require('path');
const Send = require('koa-send');
const Mount = require('koa-mount');
const Router = require('koa-router');
const Static = require('koa-static-cache');

const ApiRoutes = require('./src/server/index.js');

const staticDir = path.join(__dirname, 'static');
const router = new Router();

router.get('/control/panel', async ctx => {
    await Send(ctx, 'index.html', { root: staticDir });
});

const staticRoute = Mount('/control', Static(staticDir, { maxAge: 30 * 24 * 3600 }));

module.exports = {
    name: 'neoblog-plugin-control-panel',
    version: '0.1.0',
    description: 'article/config management panel for neoblog.',
    author: 'rocka <i@rocka.me>',
    routes: [router.routes(), staticRoute, ApiRoutes.routes],
};
