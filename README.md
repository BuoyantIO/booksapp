# Buoyant Books App

This is a sample distributed (microservices) Ruby app using Sinatra,
ActiveRecord, and ActiveResource. The app is designed to demonstrate the various
value propositions of Linkerd 2.0 including debugging, observability, and
monitoring. Some of the services in the app periodically fail. This is by design
in order to demo debugging and monitoring in Linkerd 2.0.

The application is composed of the following four services:

* [webapp.rb](webapp.rb)
* [authors.rb](authors.rb)
* [books.rb](books.rb)
* [traffic/main.go](traffic/main.go) (demo traffic generator, written in Go)

![Books Application Topology](images/topo.png)

---

## Running in Kubernetes

You can deploy the application to Kubernetes using the Linkerd 2.0 service mesh.

1. Install the `linkerd` CLI

    ```bash
    curl https://run.linkerd.io/install | sh
    ```

2. Install the Linkerd control plane

    ```bash
    linkerd install | kubectl apply -f -
    ```

3. Inject and deploy the application

    ```bash
    curl https://run.linkerd.io/booksapp.yml | linkerd inject - | kubectl apply -f -
    ```

4. Use the app!

    ```bash
    kubectl port-forward svc/webapp 7000
    open "http://localhost:7000"
    ```

5. View the Linkerd dashboard!

    ```bash
    linkerd dashboard
    ```

![Linkerd Dashboard](images/dashboard.png)

## Running with MySQL

The default booksapp configuration uses SQLite. It's also possible to run the
app with a MySQL backend, using the configs in the `k8s/` directory. The MySQL
configuration uses a separate pod for the storage backend, which allows running
multiple replicas of each of the app deployments.

1. Start by installing the MySQL backend

    ```bash
    kubectl apply -f k8s/mysql-backend.yml
    ```

2. Verify that the mysql-init job successfully completes

    ```bash
    kubectl get po
    NAME                    READY     STATUS      RESTARTS   AGE
    mysql-9bd5bcfdf-7jb2s   1/1       Running     0          3m
    mysql-init-29nxv        0/1       Completed   0          3m
    ```

3. Install Linkerd as described above; install the app configured to use MySQL

    ```bash
    linkerd install | kubectl apply -f -
    linkerd inject k8s/mysql-app.yml | kubectl apply -f -
    ```

4. Use the app!

    ```bash
    kubectl port-forward svc/webapp 7000
    open "http://localhost:7000"
    ```


### Deploy Chaos Monkey

This repo includes a Chaos Monkey script, that randomly kills a pod every 10
seconds. It is intended to be run with the Kubernetes / MySQL configuration. To
deploy, run:

    ```bash
    kubectl apply -f k8s/mysql-chaos.yml
    ```

---

## Service Profiles

In order to record per-route metrics, you can create service profiles for the
webapp, books, and authors services based on their Swagger specs:

    ```bash
    linkerd profile --open-api swagger/webapp.swagger webapp | kubectl apply -f -
    linkerd profile --open-api swagger/books.swagger books | kubectl apply -f -
    linkerd profile --open-api swagger/authors.swagger authors | kubectl apply -f -
    ```

You can then view route data for each service:

    ```bash
    linkerd routes webapp
    ```

    ```bash
    linkerd routes books
    ```

    ```bash
    linkerd routes authors
    ```

---

## Traffic Splits

You can use a modified version of booksapp to demo a trafficsplit.

1. Install `booksapp-trafficsplit.yml` which includes the MySQL backend, a
   modified version of booksapp.yml that does not introduce a FAILURE_RATE, a
   second `authors` service called `authors-clone`, and two trafficsplits.
   Linkerd has already been injected into booksapp and `authors-clone`.

    ```bash
    kubectl apply -f booksapp-trafficsplit.yml
    ```

2. Verify that two trafficsplits now exist in the `default` namespace.

    ```bash
    kubectl get ts
    ```

3. Give the app 1-2 minutes to begin sending traffic.

4. Run `watch linkerd stat ts` to verify that the trafficsplits are working. You
   should see the below results -- one trafficsplit dividing traffic 50/50
   between `authors` and `authors-clone`, one dividing traffic 100/0 between
   `webapp` and the non-existent `webapp-clone` (You can create a split between
   two services before the second service has been created).

    ```
    NAME            APEX      LEAF            WEIGHT   SUCCESS      RPS   LATENCY_P50   LATENCY_P95   LATENCY_P99
    authors-split   authors   authors           500m   100.00%   3.1rps           8ms          29ms          37ms
    authors-split   authors   authors-clone     500m   100.00%   3.5rps           8ms          23ms          37ms
    webapp-split    webapp    webapp               1   100.00%   7.3rps          26ms          74ms          95ms
    webapp-split    webapp    webapp-clone         0         -        -             -             -             -
    ```

5. When you are done, delete the app.

    ```bash
    kubectl delete -f booksapp-trafficsplit.yml
    ```

## Running Locally

You can also run the application locally for development.

1. Create, migrate, and seed the database

    ```bash
    bundle install
    bundle exec rake db:create
    bundle exec rake db:migrate
    bundle exec rake db:seed
    ```

2. Start the web app

    ```bash
    bundle exec rake dev:webapp
    ```

3. Start the authors app

    ```bash
    bundle exec rake dev:authors
    ```

4. Start the books app

    ```bash
    bundle exec rake dev:books
    ```

5. Open the website

    ```bash
    open "http://localhost:7000"
    ```

![Books App](images/booksapp.png)

## Administration

### Docker

All of the Docker images used for this application are already published
publicly and don't need to be built by hand. If you'd like to build the images
locally follow the instructions below.

1. Build the `buoyantio/booksapp` image

    ```bash
    docker build -t buoyantio/booksapp:latest .
    ```

2. Build the `buoyantio/booksapp-traffic` image

    ```bash
    docker build -t buoyantio/booksapp-traffic:latest traffic
    ```
