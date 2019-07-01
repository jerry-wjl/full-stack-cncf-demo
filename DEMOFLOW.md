Demo Flow
=========

How to demo the app
-------------------

Typically you can show 4 things.

  1. Populate the database with new data (will not trigger a build)
  2. Edit a file in git and commit it (will trigger a build and rolling upgrade)
  3. Scale up kubernetes deployment (edit kubernetes/cncfdemo.yml and commit which will trigger a build and rolling upgrade)
  4. Show metrics - i.e do some sales and show real time data getting populated.
  5. Generate some load and see the autoscaling trigger

Before You Begin
----------------

Before we begin the demo walk through, there are a couple things left to do.

1. Start Prometheus
2. Start Grafana
3. Stock the shop