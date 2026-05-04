const dataSource = require('../services/dataSource');

beforeAll(async () => {
  // Initialize in-memory data source for tests
  await dataSource.init(false);
});
