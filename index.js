'use strict';

const path = require('path');
const crypto = require('crypto');
const Send = require('koa-send');
const Mount = require('koa-mount');
const Router = require('koa-router');
const Static = require('koa-static-cache');

const ApiRouter = require('./src/server/api-router');

class PluginControlPanel {
    static get meta() {
        return {
            name: 'neoblog-plugin-control-panel',
            version: '0.1.0',
            description: 'article/config management panel for neoblog.',
            author: 'rocka <i@rocka.me>',
        };
    }

    constructor(options = {}) {
        let jwtSecret, jwtOptions, apiRouter;
        if (typeof options.jwtSecret === 'string') jwtSecret = options.jwtSecret;
        else jwtSecret = crypto.randomFillSync(Buffer.alloc(512)).toString('hex');
        if (typeof options.jwtOptions === 'object') jwtOptions = options.jwtOptions;
        if (typeof options.usr === 'string' && typeof options.pwd === 'string') {
            apiRouter = new ApiRouter(jwtSecret, jwtOptions, options.usr, options.pwd, options.profile);
        } else {
            throw new Error('usr & pwd must be specified.')
        }

        const staticDir = path.join(__dirname, 'static');
        const router = new Router();

        router.get('/control/panel', async ctx => {
            await Send(ctx, 'index.html', { root: staticDir });
        });

        const staticRoutes = Mount('/control', Static(staticDir, { maxAge: 30 * 24 * 3600 }));

        const apiRoutes = Mount('/control/api', apiRouter.routes);

        return Object.assign(PluginControlPanel.meta, {
            routes: [router.routes(), staticRoutes, apiRoutes],
        });
    }
}

module.exports = PluginControlPanel;
