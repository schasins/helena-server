//$($.post('http://localhost:3000/allpagerelations', { url: "www.test2.com" }, function(resp){ console.log(resp);} ));

//$($.post('http://localhost:3000/newdatasetsid', {}, function(resp){console.log(resp); saveSomeData(resp.id);}));
function saveSomeData(id){
	$.post('http://localhost:3000/datasetslice', {id: id, values: {"a":[[0,0]], "b":[[0,1]], "c": [[1,0]], "d": [[1,1]]}});
}
