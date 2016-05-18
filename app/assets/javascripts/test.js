$($.post('http://localhost:3000/saverelation', { relation: {name: "test", url: "www.test.com/test-test", selector: "test", selector_version: 1}, columns: [{name: "col1", xpath: "a[1]/div[1]", suffix: "div[1]"}] } ));

$($.post('http://localhost:3000/retrieverelation', { xpaths: ["a[1]/div[1]"], url: "www.test.com/test-test" } ));