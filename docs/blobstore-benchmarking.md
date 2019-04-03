# Running Blobstore Benchmarks

If you suspect your blobstore is not performing adequately, you may want to run our benchmarking utility:

`bosh ssh api/0 -c "sudo /var/vcap/jobs/cloud_controller_ng/bin/perform_blobstore_benchmarks"`

This runs a small series of performance experiments that emulate the load that a CC might put on a blobstore.

Output from an example run against a local, virtualized, `singleton-blobstore` backed by nginx and WebDAV:
```
resource match timing: 1217.462632979732ms
package upload timing: 13.919375953264534ms
package download timing: 9.604769991710782ms
downloaded 20 buildpacks, total 89514967 bytes read
buildpack download timing: 1801.0983020067215ms
droplet upload timing: 7.320249045733362ms
droplet download timing: 2.5244889548048377ms
big droplet upload timing: 2160.5330359889194ms
big droplet download timing: 3950.6868550088257ms
```

The experiments are as follows:

##### resource match 
Resource match calls actual CC resource matching code against 64Mb of bogus application code. 
Resource matching is a process where CC compares package contents by asking the blobstore about the existence of each package file using its checksum.
##### package upload and download
Uploads and then downloads a 64Mb zipfile of the aforementioned application code.
##### buildpack download 
Downloads each of the installed Buildpacks from the blobstore
##### droplet upload and download
Uploads and then downloads the 64Mb zipfile as a droplet
##### big droplet upload and download
Uploads and then downloads a 496Mb zipfile as a droplet


                                                                                     4
