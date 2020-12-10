#!/usr/bin/env python3
''' MOC Reporting build.py
    Builder script for the MOC Reporting Project

    Code Refrences:
    [1] https://docker-py.readthedocs.io/en/stable/client.html
    [2] https://docker-py.readthedocs.io/en/stable/images.html
    [3] https://github.com/openshift/openshift-client-python
    [4] https://github.com/openshift/openshift-client-python/blob/main/examples/templates.py

From the project root dir:
`$ ./build.py --all --full`: Build, Publish, Deploy all
`$ ./build.py --images get-info --full`: Build, Publish, Deploy only get-info
`$ ./build.py --all --actions deploy`: Only deploy all (not recommended)

One issue I need to point out: I was never able to get Publishing directly to the docker 
instance w/i OpenShift working, and was bouncing off of docker hub as a result. You'll 
need to recreate my setup which I did not get the opportunity to automate. In docker hub, 
create 'imagestreams' for each of the images: `moc_reporting_testing-${%s/-/_/<imagename>}`, 
(that is, change '-' to '_' in <imagename>) and change the default repo (second argument 
of `os.env` in assignment to `DOCKER_REPO`; line 29) to the account/organization you made 
the repos. Then in the OS registry console, adjust the reporting images to point to your 
newly created streams in Docker Hub. 

'''

import argparse
import os
import os.path
import time
import pprint

from contextlib import contextmanager
from functools import partial

import docker
import openshift as oc


IMAGE_ROOT = "docker-images"
IMAGE_VERSION = os.getenv("IMAGE_VERSION", time.strftime("edge-%Y%m%d-%H%M%S"))
OPENSHIFT_TEMPLATE = "JobTeamplate.yaml"

@contextmanager
def pushd(dirname):
  ''' str -> None
      Context manager simulates shell pushd in with statements
  '''
  cwd = os.getcwd()
  os.chdir(dirname)
  yield
  os.chdir(cwd)

def readfile(fname):
  ''' str -> None
      Read in the whole file
  '''
  with open(fname, 'r', encoding='ascii') as ifp:
    return ifp.read()

def _build(dcli, image):
  ''' docker.DockerClient x str -> None
      Calls build routines for the given image
  '''
  image_dir = os.path.join(IMAGE_ROOT, image)
  image_tag = f"{image}:{IMAGE_VERSION}"
  dcli.images.build(path=image_dir, tag=image_tag)

@contextmanager
def build(dcli, _proj, _to):
  ''' docker.DockerClient x (Unused) x (Unused) -> ((str) -> None)
  '''
  yield partial(_build, dcli)

def _publish(dcli, image):
  ''' docker.DockerClient x str -> None
      Calls publish routines for the given image
  '''
  dcli.images.push(image, IMAGE_VERSION)
  # TODO: ask oc to import?

@contextmanager
def publish(dcli, project, timeout):
  ''' docker.DockerClient x str x int -> ((str) -> None)
  '''
  with oc.project(project), oc.timeout(timeout):
    yield partial(_publish, dcli)

def _deploy(image):
  ''' str -> None
      Deploys the given image to Openshift using the oc API
  '''
  with pushd(os.path.join(IMAGE_ROOT, image)):
    if os.path.isfile(OPENSHIFT_TEMPLATE):
      ocobj = oc.create(
                oc.APIObject(string_to_model=readfile(OPENSHIFT_TEMPLATE))
                  .process())
      for obj in ocobj.objects():
        print(f"Created: {obj.model.kind}/{obj.model.metadata.name}")
        print(obj.as_json(indent=4))
    else:
      print(f"WARN: Missing oc template {OPENSHIFT_TEMPLATE} for image {image}")

@contextmanager
def deploy(_dcli, project, timeout):
  ''' (Unused) x str x int -> ((str) -> None)
  '''
  with oc.project(project), oc.timeout(timeout):
    yield _deploy

IMAGES = [ "cpan_images", "init-db", "get-info" ]
WORK_MAP = {
    "build": build,
    "publish": publish,
    "deploy": deploy
}

def parse_args(routines, images):
  ''' parse_args: []str x []str -> argparse.Namespace
      Runs ArgumentParser Routines
  '''
  parser = argparse.ArgumentParser(description="MOC reporting build script")

  imggrp = parser.add_mutually_exclusive_group(required=True)
  imggrp.add_argument("--all", action="store_true")
  imggrp.add_argument("--images", nargs="*", choices=images)

  parser.add_argument("--oc-timeout", default=900,
                      help="Timeout for Openshift actions in seconds")
  parser.add_argument("--project", default="reporting-testing")
  parser.add_argument("--tag", default="latest")
  parser.add_argument("actions", nargs="+", choices=routines)

  return parser.parse_args()

def main():
  ''' None -> None
      Main time
  '''
  args = parse_args(WORK_MAP.keys(), IMAGES)
  print(args)

  docker_client = docker.from_env()

  work = [WORK_MAP[step] for step in args.actions]
  tgt_images = IMAGES if args.all else args.images

  print("work: ", work)
  print("images: ", tgt_images)
  print(f"tag: {args.tag}")
  
  for actor in work:
    with actor(docker_client, args.project, args.oc_timeout) as action:
      for image in tgt_images:
        action(image,args.tag)

if __name__ == '__main__':
  main()
