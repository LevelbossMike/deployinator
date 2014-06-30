# Skeleton for small libraries

This is a skeleton to be used as starting point for small and independent libraries.

It includes:

- [broccoli.js](https://github.com/broccolijs/broccoli) for building.
- [Bower](http://bower.io/) for packaging. 
- [es6-module-transpiler](https://github.com/square/es6-module-transpiler) for working with ES6 modules.
- [broccoli-coffeelint](https://github.com/runtastic/broccoli-coffeelint) for linting adapted to the [Runtastic Styleguide](https://github.com/runtastic/coffeescript-style-guide).
- [Karma](http://karma-runner.github.io/) for fast testing with [qunit-bdd](https://github.com/square/qunit-bdd).

## Prerequisites
If not already installed on your local machine (you can test it e.g. with `$
which karma`): 

- Install Broccoli: `$ npm install -g broccoli-cli`
- Install Karma: `$ npm install -g karma-cli`

## Install dependencies
- Install npm packages: `$ npm install`
- Install Bower packages: `$ bower install`

## Start Services
- Start Broccoli: `$ broccoli serve`
- Start Karma: `$ karma start`

Please don't forget to update the name and version also in `package.json` and `bower.json` before submitting it. 
