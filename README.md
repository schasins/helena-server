# How to deploy the Helena server

## Clone and archive the GitHub repo
On your development machine, ensure that `git` is installed, and execute the command `git clone https://github.com/schasins/helena-server.git`. Then `cd helena-server` and execute the command `git archive -v -o helena-server.zip --format=zip HEAD`. (This generates a ZIP archive of the latest commit in `master`.)

## Create an RDS instance for the database in your AWS account
Assuming you already have an AWS account, open the web console and select "Services → RDS". Create a new PostgreSQL database using the "production" template, with DB instance ID "helena", master username "helena", instance type `db.t2.large`, and 100GB SSD storage. Under "Connectivity → Additional connectivity configuration", select "Publicly accessible → Yes". (Note that you will need the master password and the auto-generated database hostname for the next step.) After the database has been created, try to connect to it from the terminal with the `psql` command-line tool:

```
PGPASSWORD=YOUR_MASTER_PASSWORD psql -h YOUR_RDS_HOSTNAME -p 5432 -U helena
```
(If you can't connect to your database, verify that your RDS security group has an inbound rule permitting access to TCP port 5432 from your development machine's IP.)

Now you can create the Helena production database on your new RDS instance (install `bundler` with `gem install bundler` if you haven't already):

```
HELENA_SERVER_DATABASE_HOST=YOUR_RDS_HOSTNAME HELENA_SERVER_DATABASE_PASSWORD=YOUR_MASTER_PASSWORD RAILS_ENV=production bundle exec rake db:create db:schema:load
```

Verify that the (empty) Helena production database now exists by logging into your RDS instance and connecting to the Helena database:

```
PGPASSWORD=YOUR_MASTER_PASSWORD psql -h YOUR_RDS_HOSTNAME -p 5432 -U helena

helena=> \l
 visual-pbd-scraping-server_production | helena   | UTF8     | en_US.UTF-8 | en_US.UTF-8 |

helena=> \c visual-pbd-scraping-server_production

visual-pbd-scraping-server_production=> \d
                             List of relations
 Schema |                     Name                      |   Type   | Owner
--------+-----------------------------------------------+----------+--------
 public | ar_internal_metadata                          | table    | helena
 public | columns                                       | table    | helena
 public | columns_id_seq                                | sequence | helena
 public | dataset_cells                                 | table    | helena
 public | dataset_cells_id_seq                          | sequence | helena
 public | dataset_links                                 | table    | helena
 public | dataset_links_id_seq                          | sequence | helena
 public | dataset_row_dataset_cell_relationships        | table    | helena
 public | dataset_row_dataset_cell_relationships_id_seq | sequence | helena
 public | dataset_rows                                  | table    | helena
 public | dataset_rows_id_seq                           | sequence | helena
 public | dataset_values                                | table    | helena
 public | dataset_values_id_seq                         | sequence | helena
 public | datasets                                      | table    | helena
 public | datasets_id_seq                               | sequence | helena
 public | domains                                       | table    | helena
 public | domains_id_seq                                | sequence | helena
 public | program_runs                                  | table    | helena
 public | program_runs_id_seq                           | sequence | helena
 public | program_sub_runs                              | table    | helena
 public | program_sub_runs_id_seq                       | sequence | helena
 public | program_uses_relations                        | table    | helena
 public | program_uses_relations_id_seq                 | sequence | helena
 public | programs                                      | table    | helena
 public | programs_id_seq                               | sequence | helena
 public | relations                                     | table    | helena
 public | relations_id_seq                              | sequence | helena
 public | schema_migrations                             | table    | helena
 public | transaction_cells                             | table    | helena
 public | transaction_cells_id_seq                      | sequence | helena
 public | transaction_locks                             | table    | helena
 public | transaction_locks_id_seq                      | sequence | helena
 public | transaction_records                           | table    | helena
 public | transaction_records_id_seq                    | sequence | helena
 public | urls                                          | table    | helena
 public | urls_id_seq                                   | sequence | helena
```

## Create an Elastic Beanstalk application in your AWS account
Assuming you already have an AWS account, open the web console and select "Services → Elastic Beanstalk". Click "Create New Application"  and name it "helena-server" or any other name of your choice. Then click "Create Environment" and select "Web Application". Choose a unique domain name for the endpoint and select "Ruby" from the dropdown under "Platform". Under "Application Code", select "Upload your code" and choose the archive file you created in the first step. Then click "Configure more options", and on the next page, click "Change platform configuration". In the pop-up dialog, select "Passenger with Ruby 2.6". Next, click "Software → Modify", and check "Enable log streaming". Then add the following environment properties:

| Name      | Value |
| ----------- | ----------- |
| `HELENA_SERVER_DATABASE_HOST` | _Fully qualified domain name of the RDS instance you created in the previous step_ |
| `HELENA_SERVER_DATABASE_PASSWORD` | _Configured password of the RDS instance you created in the previous step_ |
| `SECRET_KEY_BASE` | _Random string generated using `rake secret` from Rails or `openssl rand -hex 64` from a Linux or Mac terminal_ |

Next, click "Instances → Modify" and select "t2.xlarge" from the "Instance type" dropdown. Then enter "100GB" in the "Root volume → Size" textbox. Click "Continue", and if you want to remotely log into your server instance, select an <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair">SSH key pair</a> under "Security → EC2 Key Pair". Finally, enter a contact email address under "Notifications". Click "Create Environment" and your new server should be ready to service requests within a few minutes.

## Debug your server using application logs
If you enabled streaming logs in the preceding step, you can view your application logs in real time. Starting in the Elastic Beanstalk console, from "All Applications → helena-server → _your environment_", click "Configuration → Software → Modify → Log groups". This will open the CloudWatch console to your environment's log groups. To view application-level errors and diagnostic messages, click the link ending in `passenger.log`. (If you've rebuilt your environment, there may be multiple instances listed; the most recent should be at the top.)

## Update your application
If you've made source code changes that you want to deploy, follow the instructions above to generate an archive file from the latest commit in your `git` repo, then navigate to the dashboard page for your current environment, click "Upload and Deploy", and select the archive file you just created. Your changes will be deployed in a few minutes. If you need to roll back to an earlier version, navigate to the "All Applications → helena-server → Application versions" page, select the source code version to deploy, and click "Actions → Deploy".
