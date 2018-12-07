---
title: Day 7: MetaCPAN, Mojolicious and OpenAPI
disable_content_template: 1
tags:
    - advent
    - development
    - openapi
    - api
author: Shawn Sorichetti
images:
  banner:
    src: '/blog/2018/12/07/openapi/banner.jpg'
    alt: 'Contract signing'
    data:
      attribution: |-
        Photo by [Cytonn Photography on Unsplash](https://unsplash.com/photos/GJao3ZTX9gU)
data:
  bio: ssoriche
  description: 'Overview of how OpenAPI was integrated into MetaCPAN with Mojolicious.'
---

During this years [meta::hack 3](http://www.olafalders.com/2018/11/21/metahack-3-wrap-report/), I was extremely fortunate to work with [Joel Berger](https://twitter.com/joelaberger) on integrating/documenting OpenAPI with the MetaCPAN API via Mojolicious.

## What is it?
OpenAPI is a specification for designing, documenting, validating and driving your RESTful API. It can be used to provide documentation to an existing API, or when creating a new one.

The OpenAPI Specification originated as the Swagger specification and was renamed to separate the API description format (OpenAPI) from the open source tooling (Swagger). The specification moved into a new GitHub repository, but did not change.

In the case of the MetaCPAN API, we set out to provide documentation to the existing API, but quickly moved into supporting validation to API calls as well.

---

## The tools
OpenAPI has many tools available to help, including discovery tools that will assist in writing the specification. We chose to write the definition by hand (in vim of course) and use tools to generate the documentation and to integrate the specification into MetaCPAN.

* [ReDoc](https://github.com/Rebilly/ReDoc) — OpenAPI/Swagger-generated API Reference Documentation

ReDoc creates an interactive page providing documentation and examples based on the details provided in the OpenAPI specification file. ReDoc includes a [HTML template](https://github.com/Rebilly/ReDoc#tldr) to be served as a static file for customizing how the documentation is displayed.

* [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI) — OpenAPI / Swagger plugin for Mojolicious

Reads the OpenAPI specification file and adds the appropriate routes and validations for your Mojolicious based application.

* [JSON::Validator](https://metacpan.org/pod/JSON::Validator) — Validate data against a JSON schema

Integrated into the Mojolicious::Plugin::OpenAPI module, provides the input and output validation, as well as providing validation for the specification file itself.

## Getting Started
The following strategy was used when implementing the MetaCPAN OpenAPI specification.

### The OpenAPI Specification File

With support for multiline attribute values making it much easier to read and write with less formatting, we chose YAML. JSON is also supported.

    # Define the version of the OpenAPI spec to use. Version 2.0 still uses
    # swagger as the key
    swagger: "2.0"
    # general information about the API
    info:
      version: "1.0.0"
      title: "MetaCPAN API"
    # common path shared throughout the API
    basePath: "/v1"

#### Defining an Endpoint

Each of the paths available to the API are defined within the paths object.

    paths:
      # The path to the endpoint
      /search/web:
        # The HTTP method that the endpoint accepts
        get:
          # A unique identifier for the method
          operationId: search_web
          # This attribute points to the name of the class in the appliction
          # and the method to call separated by `#`
          x-mojo-to: Search#web
          # A description of the API Endpoint
          summary: Perform API search in the same fashion as the Web UI

#### Defining Parameters

Each method can define its own parameters.

    # The parameters that the HTTP method accepts
    parameters:
      # The name of the parameter
      - name: q
        # The location to parse the parameter from
        in: query
        # Document what the parameter is. This example uses the YAML HEREDOC
        # syntax to make the description easier to read and write.
        description: |
          The query search term. If the search term contains a term with the
          tags `dist:` or `module:` results will be in expanded form, otherwise
          collapsed form.

          See also `collapsed`
        # The type of the value that the API accepts
        type: string
        # Define the attribute as required
        required: true
      # The rest of the parameters that the API accepts
      - name: from
        in: query
        description: The offset to use in the result set
        type: integer
        # If the API applies a default to an attribute if it isn't specified.
        # Let the us know what it is.
        default: 0
      - name: size
        in: query
        description: Number of results per page
        type: integer
        default: 20
      - name: collapsed
        in: query
        description: |
            Force a collapsed even when searching for a particular
            distribution or module name.
        type: boolean

#### Defining the Response

The OpenAPI specification allows you to define each response to a method call, this includes both specific and generic error handling. Definitions are defined per HTTP status code.

    responses:
      # HTTP 200 response
      200:
        description: Search response
        # The schema defines what the result will look like
        schema:
          type: object
          properties:
            total:
              type: integer
            took:
              type: number
            collapsed:
              type: boolean
            results:
              title: Results
              type: array
              items:
                # While items can be further broken into properties per item,
                # type `object` is a catch all
                type: object

### Advanced Definitions

#### Reusing definitions through references
The specification allows for reuse by means of [JSON references](https://tools.ietf.org/html/draft-pbryan-zyp-json-ref-03). The `$ref` attribute is a relative pointer to the file and section (again separated by `#`) to include at the indicated point.

            results:
              title: Results
              type: array
              items:
                $ref: "../definitions/results.yml#/search_result_items"

The v2.0 specification does have restrictions on where references can be use, which does cause repetition in the specification file. The v3.0 specification has corrected these issues, and also allows for `http` references.

#### Might be `null`

There are times that a property of an object might be `null`. In the MetaCPAN API the favourite count may either be an integer representing how many people have favourited the distribution, or `null`. Using a list for the property `type` allows the property to contain both.

    favorites:
      type:
        - "integer"
        - "null"

### The MetaCPAN Specification

The entire specification doesn’t need to be complete in order to get OpenAPI up and running. When documenting an existing API, it’s possible to with one portion of the API. With MetaCPAN we started with the search endpoints.

The [spec file can be viewed here](https://github.com/metacpan/metacpan-api/blob/master/root/static/v1.yml) and the [API documentation here](https://fastapi.metacpan.org/static/index.html)

## Further Reading
The [OpenAPI Specification repository](https://github.com/OAI/OpenAPI-Specification) includes full documentation and many examples of varying levels of details.

The [OpenAPI Map](https://openapi-map.apihandyman.io) is an interactive site to aid in working with the OpenAPI Specification.
