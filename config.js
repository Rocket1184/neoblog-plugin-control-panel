const PluginControlPanel = require('.');

module.exports = {
    title: 'Plugin Control Panel',
    articleDir: './node_modules/@neoblog/neoblog',
    plugins: [
        new PluginControlPanel({ usr: 'root', pwd: 'root' })
    ],
    templateArgs: {
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
