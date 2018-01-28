const PluginControlPanel = require('.');

module.exports = {
    title: 'Plugin Contorl Panel',
    articleDir: './node_modules/neoblog/example/article',
    plugins: [
        new PluginControlPanel({ usr: 'root', pwd: 'root' })
    ],
    templateArgs: {
        side: {
            title: 'NeoBlog',
            items: [
                [
                    {
                        name: 'Index',
                        link: '/'
                    }
                ],
                [
                    { text: `OS: ${process.platform} ${process.arch}` },
                    { text: `Node: ${process.version}` }
                ]
            ]
        }
    }
};
