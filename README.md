# neoblog-plugin-control-panel

![npm](https://img.shields.io/npm/v/@neoblog/plugin-control-panel.svg)

Article/config management panel for neoblog, written in [Elm](http://elm-lang.org/) .

## Features

- Article
  - [x] list
  - [x] create
  - [x] modify
  - [ ] delete
  - [ ] group by tags
- Config
  - [ ] read
  - [ ] write
  - [ ] lint

## Usage

Install `@neoblog/plugin-control-panel` with `npm`, and see config example at [config.js](./config.js) .

Once plugin was installed, you can login at `/control/panel` .

## Plugin Options

```ts
new PluginControlPanel(options: IPluginOptions);

interface IPluginOptions {
    usr: string;        // login username
    pwd: string;        // login password
    jwtSecret: string;  // JSON Web Token secret
    jwtOptions?: any;   // jsonwebtoken sign options (see below)
}
```

jwtOptions default to `{ expiresIn: '2d' }`. Learn more [here](https://github.com/auth0/node-jsonwebtoken#jwtsignpayload-secretorprivatekey-options-callback) for infomation about Jwt options.
