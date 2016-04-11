---
layout: post
title: Web applications with TypeScript and Sequelize
---

I've been using TypeScript professionally for a short while now and enjoy working with it. I think it really smooths out some of the rough parts of developing server software in JavaScript. At Colibri, I've been working on a NodeJS project that is starting to move to TypeScript with some success. One part of that project, the storage subsystem, hasn't been ported yet and I've done some research to best understand how to tackle it.

With that, I created a small proof of concept application that demonstrates how Express web applications that use Sequelize (ORM) on top of Postgres can be written in TypeScript.

[https://github.com/ngerakines/express-typescript-sequelize](https://github.com/ngerakines/express-typescript-sequelize)

I think there is a time and a place for tools like gulp and grunt, but most of the time they aren't necessary. For this project, I'm using the `scripts` block to create a chain of actions. The `lint` target uses the [tslint](https://github.com/palantir/tslint) tool to verify that standards are enforced. That target is dependency of the `build` target the runs the `tsc` command that compiles the TypeScript code into JavaScript. The `build` target is a dependency of the `test` target that executes the unit tests through [mocha](https://mochajs.org/) and [istanbul](https://github.com/gotwarlost/istanbul). After tests are run, that same tool verifies that coverage requirements are met.

The end result is that I use two commands to build and run this application:

    $ npm run build && npm start

This application has a handful of dependencies but the main ones are [express](http://expressjs.com/), [sequelize](http://docs.sequelizejs.com/en/latest/), and [TypeScript](https://www.typescriptlang.org/). I've also gotten pretty used to including bluebird, moment, lodash, and node-uuid by default in everything that do. For template rendering, I'm using [dustjs](http://www.dustjs.com/), which I had never used before and find appealing.

The application code is split into three areas:

* src/index.ts is where the express application is constructed and configured.
* src/routes.ts contains the definition of the ApplicationController that does all of the request handling work.
* src/storage.ts contains the storage manager, including the sequelize implementation.

The storage manager is a fairly simple interface that is used to define and interact with the Account and Address objects. For this small example application, I just have the two. An account is a registered site user (register, login, logout, etc) and they have one or more addresses as managed on the settings page. The relationship between accounts and addresses is one to many.

When using the Sequelize library in a TypeScript application, you need to know how the object interfaces are defined and relate to each other. The important thing to know is that for each application object (account, address, etc) there are 3 interfaces that need to be defined: An attribute definition interface, an instance interface, and a model interface.

```ts
export interface AccountAttribute {
    id?:string;
    name?:string;
    email?:string;
    password?:string;
}

export interface AccountInstance extends Sequelize.Instance<AccountAttribute>, AccountAttribute {
}

export interface AccountModel extends Sequelize.Model<AccountInstance, AccountAttribute> { }
```

In the above code block, the `AccountAttribute` is defined. That object has 4 managed fields including the id (a generated uuid), name, email, and password. That interface is then referenced by the `AccountInstance` and `AccountModel` interfaces. The instance interface is used to describe what an instantiated instance of an account object looks like and how it behaves. It includes all of the attributes of the attribute interface but also some sequelize specific methods like `updateAttributes` and `save`. The model interface is used to describe how, through sequelize, instances of objects are managed. The model interface includes methods like `find` and `create`.

When the sequelize implementation of the storage manager is created, within the constructor the `define` method is called which binds the schema definition and model interface to an instance of the model and it can be used.

```ts
this.Account = this.sequelize.define<AccountInstance, AccountAttribute>("Account", {
        "id": {
            "type": Sequelize.UUID,
            "allowNull": false,
            "primaryKey": true
        },
        "name": {
            "type": Sequelize.STRING(128),
            "allowNull": false
        },
        "email": {
            "type": Sequelize.STRING(128),
            "allowNull": false,
            "unique": true,
            "validate": {
                "isEmail": true
            }
        },
        "password": {
            "type": Sequelize.STRING(128),
            "allowNull": false
        }
    },
    {
        "tableName": "accounts",
        "timestamps": true,
        "createdAt": "created_at",
        "updatedAt": "updated_at",
    });
```

In the above code block, the private `Account` variable is set and the schema defined. In the third param I'm instructing sequelize to manage the created at and updated fields, but I'm specifying what the column names should be. Later in that same storage manager implementation, I reference those model instances like this:

```ts
register(name:string, email:string, rawPassword:string):Promise<any> {
    return this.sequelize.transaction((transaction:Sequelize.Transaction) => {
        let accountId = uuid.v4();
        return this.hashPassword(rawPassword)
            .then((password) => {
                return this.Account
                    .create({
                        id: accountId,
                        name: name,
                        email: email,
                        password: password
                    }, {transaction: transaction})
            });
    });
}
```

The rest of the application is pretty standard. The storage manager is created early and used in both creating the express application as well as the application handler. Open an issue on GitHub or message me on twitter [@ngerakines](https://twitter.com/ngerakines) if you've got any questions or comments.
