const PluginControlPanel = require('.');

module.exports = {
    title: 'Plugin Control Panel',
    articleDir: './node_modules/@neoblog/neoblog/example/article',
    plugins: [
        new PluginControlPanel({ usr: 'root', pwd: 'root' })
    ],
    templateArgs: {
        head: {},
        side: {
            title: 'NeoBlog',
            items: [
                [
                    {name: 'Index', link: '/'},
                    {name: 'Manage', link: '/control/panel'}
                ],
                [
                    { text: `OS: ${process.platform} ${process.arch}` },
                    { text: `Node: ${process.version}` }
                ]
            ]
        }
    }
};
