module.exports = {
    title: 'Plugin Contorl Panel',
    articleDir: './node_modules/neoblog/example/article',
    plugins: [
        require('.')
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
