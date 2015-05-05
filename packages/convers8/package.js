Package.describe({
  name: 'zhenya:convers8',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: '',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');

  api.use([
    'coffeescript', 
    'templating', 
    'less', 
    'underscore',
    'reactive-var',
    'session',
    'zhenya:reveal'], 'client');

  api.addFiles([
    'visuals.html',
    'visuals.coffee',
    'visuals.less',
    'visuals/text/text.html',
    'visuals/text/text.coffee',
    'visuals/text/text.less',
    'visuals/question/question.html',
    'visuals/question/question.coffee',
    'visuals/question/question.less'
    ], 'client');

});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('zhenya:convers8');
});
