
Massachusetts Open Cloud (MOC) Reporting
=============

## Goal

The ultimate goal of the MOC Reporting project (MOC Reporting System)
is to generate actionable business objects in the form of human readable summary usage reports.
These reports will summarize just OpenStack usage for now. The system must be able to generate these reports across the axes of Institution, Project, and User.
Furthermore, the system must also be able to generate intermediate CSV artifacts
that act as a snapshot of the database holding all usage information being collected
from OpenStack. CSV dumps will be created for all object and relationship tables
for a user-specified time period.


## Stretch Goals
Although the current goal of the project revolves around generating reports and CSV dumps for just OpenStack, if time permits, there are also stretch goals that can be implemented, and are as follows:
 1. Extend functionality of the MOC Reporting System
so that the system will be able to collect data from and generate CSV files and reports
for Zabbix, Openshift, and Ceph.
 2. Develop, deploy and automate the process of consistency and quality checks of the data collected.
 3. Develop pricing model for billing reports for paying customers.


## Users and Personas

Three Primary Groups are relevant for discussing the goals of the project. The
following definitions will be used throughout this document and repository:
 - MOC Administrators: technical personnel at the MOC who are responsible for
   MOC operations and generating MOC billing and usage reports
 - Partner Administrators: Persons-of-Contact at MOC partner corporations
   and institutions who are responsible for the partner's investment in and
   participation with the MOC
 - Partner Users: researchers and engineers who use the MOC in their day-to-day
   tasks

The project will begin with MOC Administrators (Rob) who need to produce
usage reports for the partner institutions. The project is anticipated to expand
to other users, however, those users' personas are not yet well defined.


## Scope

At the highest level, the system must be able to tally the total usage for every
Virtual Machine at the MOC and produce Openstack usage reports that can be sent to customers for viewing, as well as produce intermediary data store in the form of CSV dumps that serve as "raw" data that can be provided to customers (if customers wanted to generate their own reports). Further, the system must be able to aggregate that
data across three major segments:
 1. Projects
 2. Institutions
 3. Users

Each pair of segments has the following cardinality:
 - Project-Institution: Many-to-Many
 - Project-User: Many-to-Many
 - User-Institution: Many-to-One


"Projects" refers to collections of MOC Service instances. Each Project defines
an area of control and will have one User that is responsible for that Project.
Further, Projects are a recursive data type: sub-projects can be defined on a
given project, and reports generated for that project must include appropriately
labeled usage data for all sub-projects. The project tree will be rooted in a
node that represents the whole of the MOC. Lastly, a notion of relative buy-in /
investment will need to be defined for all projects with multiple funding
Institutions.

The system created will automatically gather data from OpenStack
and build an intermediary store of usage data from which reports and dump files can be generated. The generated
usage data will be persistent. Length of persistency shall be defined at
run-time by the MOC Administrator.

The system will be able to produce reports accurate to one hour. The system may
be extend to provide finer reporting capabilities. Reports generated must be
consistent with the raw data collected from OpenStack. The system must run
automated consistency verification routines against all data source streams.

The system must support the following front-ends for data export:
 - CSV File, a Dump of all usage data over a given time period
 - PDF File, a Human-Readable Report

A complete billing system with graphical front-end is considered beyond the
scope of this project, however defining a model for pricing will be attempted if
time allows.

If time permits and the initial Scope of the project has been satisfied and completed,
We can extend this project to collect data from and produce reports for
Openshift, Ceph, and Zabbix services, again across the three major segments.


## Features

1. OpenStack Usage data collector
    - Data that will be collected include:
     - [User](https://docs.openstack.org/mitaka/install-guide-obs/common/glossary.html#term-user)
     - [Flavors](https://docs.openstack.org/mitaka/install-guide-obs/common/glossary.html#term-flavor)
     - [Router](https://docs.openstack.org/mitaka/install-guide-obs/common/glossary.html#term-router)
     - [Neutron Information](https://docs.openstack.org/mitaka/install-guide-obs/common/get_started_networking.html)
       - [Networks](https://docs.openstack.org/mitaka/install-guide-obs/common/glossary.html#term-network)
       - [Subnets](https://docs.openstack.org/mitaka/install-guide-obs/common/glossary.html#term-subnet)
       - [Floating IPs](https://docs.openstack.org/mitaka/install-guide-obs/common/glossary.html#term-floating-ip-address)
     - [Instances](https://docs.openstack.org/mitaka/install-guide-obs/common/glossary.html#term-instance)
     - [Volumes from Cinder](https://docs.openstack.org/mitaka/install-guide-obs/common/glossary.html#term-volume)
     - [Panko Data](https://docs.openstack.org/panko/latest/webapi/index.html)
    - Data collected will be stored in a PostgreSQL database
    - Data collection scripts will be run every 15 minutes
    - Python 3 or Perl Scripts

2. Database
    - Contains raw data from OpenStack
    - Contains tables for Institutions, Users, and Projects.
    - Database is auditable (READ actions only performed)
    - PostgreSQL RDBMS
    - The ER diagram below shows the data model structure.
    ![ER Diagram](/images/ER_diagram.png)

3. Data pipeline
    - Extracts raw OpenStack usage data from PostgreSQL database.
    - Processes raw data into CSV files
      - Each CSV file containing all entries from a user-specified time period.
      - Each CSV file is mapped to a single table within the database.
    - Pipeline will produce data consistent with MOC logs
    - Pipeline will be automated to run every day.
    - CSV Files will be stored on MOC servers and will be persistent
    - Can only perform READ actions on the database containing raw OpenStack data.
4. "Front-end" server for accessing processed data
    - Provides Interface point for user utilities for generating reports
5. CSV Database dump utility
    - Will write all entries in the usage database over a specified time period
      to downloadable files
    - Allows checking of consistency with MOC Logs
6. Basic Monthly Aggregate Usage Report Generator
    - Will extend current work that produces elementary reports
7. Hardware/VM Specs:
  - OpenStack x86 VMs
  - TBD



## Solution Concept
#### Global Overview

The system can conceptually be understood has consisting of three major layers:
 1. MOC Service Provider Systems
 2. The Data Collection Engine
 3. "Front-End" Consumers

![Solution Architecture Diagram](/images/architecture_diagram.png)

#### Design Implications and Discussion

Below is a description of system components that are being used to implement the features:

 - PostgreSQL DBMS: Database
 - Perl : Data Collection 
 - Python : Building data dump utilities
     - Psycopg2 library: PostgreSQL connection management
 - R : Business Analytics and Report Generation
 - Openstack: Open source VM federation management
 - Openshift: Open source containerization software
 
Layer 1 consists of the "real services" on the MOC that are responsible for
providing the MOC's Virtualization Services. OpenStack is the keystone element
here. Layer 2 will be implemented during the course of this project. It will be
responsible for using the interfaces provided by the services in Layer 1 to collect,
aggregate and store data and provide an API to the Layer 3 services. Layer 2 will also provide functionality to dump data store into an intermediary raw format in the form of CSV dumps. Proof-of-Concept
demonstration applications at Layer 3 will be developed to showcase the ability
of the Layer 2 aggregation system. The finished system will be deployed on MOC VMs. 


## Minimum Acceptance Criteria
 1. The system must be able to both generate a human readable report
    summarizing OpenStack usage and dump across Institutions, Projects, and Users.
 2. The system creates intermediate CSV files that represent the state of the
    database tables from a current period of time and be stored on MOC servers.
 3. Openstack data collection, storing into databases, and saving as CSV files will be automated.
 
## Reach Acceptance Criteria 
 1. The system must be able to both generate a human readable report
    summarizing Openshift usage and dump across Institutions, Projects, and Users.
 2. The system must be able to both generate a human readable report
    summarizing Ceph usage and dump across Institutions, Projects, and Users.
 3. The system must be able to both generate a human readable report
    summarizing Zabbix usage and dump across Institutions, Projects, and Users.
 4. The system will have automated data quality and consistency checks.
 5. Openshift, Ceph and Zabbix usage data collection, storing into databases, and saving as CSV files will be automated.


## Release Planning
#### Release #1: (Sept 26)
 - Analysis of requirements and setting up the PostgreSQL database on the test environment along with other dependencies.
 - Second draft of Project Proposal after further investigation. Constructed entity relationship diagrams, cardinality relationship diagrams, and solution architecture diagrams.
 - Create Script to extract data from database and convert it into CSV files so that it could be further processed and customized reports could be generated from it.

#### Release #2: (Oct 10)
 - Implement data validation for csv dump.
 - Create Report generation tool which will convert the csv data into customized report PDFs.
    - Generate usage reports for Openstack
 - Create setup script that would install all the dependencies, schedule the csv generating script and setup the report generation tool in Linux machine.
 - Automate the system to run periodically
    - Hook the script generating csv script to the report generation tool that would allow the sequential execution of the two.
 - Add functionality to csv dump script to be able to pull data from database in prod environment
    - Needs to be configurable at run time.

#### Release #3: (Oct 24)
 - Implement tool for generating reports for Openshift.
    - Extend data collection capabilities.
    - Extend data model to incorporate Openshift.
    - Extend report generation tool to generate reports for Openshift.
##### ...

#### Release #4: (Nov 7)
 - Implement tool for generating reports for Zabbix.
    - Extend data collection capabilities for Zabbix.
    - Extend data model to incorporate Zabbix.
    - Extend report generation tool to generate reports for Zabbix.
##### ...

#### Release #5: (Nov 21)
 - Implement tool for generating reports for Ceph.
    - Extend data collection capabilities for Ceph.
    - Extend data model to incorporate Ceph.
    - Extend report generation tool to generate reports for Ceph.
##### ...

#### Release #6: (Dec 5)
 - Addition or modification in the tool according to the requirement.
 - Generate reports from the aggregated data gathered from openstack, zabbix, ceph and openshift.


## Open Questions
 - What is the minimum necessary level of usage data granularity
    - What minimum level of granularity is needed internally to provide this, if
      different?
 - How often will the pipeline need to run?
 - Guidelines/Expectations for outputted report?
 - What are the hardware specs of the machines to be running this system?
 - Containerization: What software is necessary in containers to run scripts?
 - Definition of Production level
 
 ## Demo Presentations
 - [Sprint 1](https://docs.google.com/presentation/d/12604SFjpRfqNQNBQ3ePZvH79kq0-ihbKXSHs0ffKcXQ/)
 - [Sprint 2](https://docs.google.com/presentation/d/1dm3UGdc3P_4b5UifQM6C4nB_20OWXBRQcUdXFZ0owNg/)
 - [Sprint 3](https://docs.google.com/presentation/d/1NIUT4NMnndiZX0jPS-VODNg4AAYO_2hbqc_hw5cD_F4/)
 - [Sprint 4](https://docs.google.com/presentation/d/15ipVvw_tJ8az4gGcC-GOwnAKGxc-IqUGe2auCgMxTfQ/)
 - [Sprint 5](https://docs.google.com/presentation/d/1UItGtiM944jlSvJnVHLxWiUEWsnEuvF1dAEYKvO9zDY/)
 - [Jupiter Rising](https://docs.google.com/presentation/d/1ostKRN2FZnqzaJ-8uUCbqlU3tE2DqcTxGqawXl3JtXk/)
 
