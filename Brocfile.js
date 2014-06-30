var mergeTrees     = require('broccoli-merge-trees');
var exportTree     = require('broccoli-export-tree');
var compileCoffee  = require('broccoli-coffee');
var coffeelintTree = require('broccoli-coffeelint');

var lib   = 'src';
var tests = 'test';

var lintingTree = coffeelintTree(mergeTrees([lib, tests]));
var compiledCoffee = compileCoffee(lib, { bare: true });
var coffeeTests = compileCoffee(tests, { bare: true});


var exportLib = exportTree(compiledCoffee, {
  destDir: 'dist'
});

var exportTests = exportTree(coffeeTests, {
  destDir: 'tmp/output/test'
});

module.exports = mergeTrees([
  lintingTree,
  exportLib,
  exportTests
]);
