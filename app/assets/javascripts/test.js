$($.post('http://localhost:3000/saverelation', { relation: {name: "test", url: "www.test2.com/test-test2", selector: "test", selector_version: 1}, columns: [{name: "col1", xpath: "a[1]/div[2]", suffix: "div[1]", num_rows_in_demonstration: 10}] } ));

$($.post('http://localhost:3000/retrieverelation', { xpaths: ["a[1]/div[1]"], url: "www.test.com/test-test" } ));