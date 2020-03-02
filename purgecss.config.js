module.exports = {
  content: ["./_site/**/*.html"],
  css: ["./_site/css/tw_style.css"],
  defaultExtractor: content => content.match(/[A-Za-z0-9-_:/]+/g) || []
};
