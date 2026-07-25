# Contributing

- Found a bug? Have an idea? Open an [issue][1].
- Code improvements? Create a [pull request][2].

## Local setup

Requirements:

- `make`
- `docker`

> If you don't have Docker, you can install in your system the tooling and
> shells listed in `Dockerfile.dev` and append `docker_run=` to the `make`
> commands.

## Linting and testing

```bash
make lint  # takes a few seconds
make test  # takes a few minutes
```

For a quicker test using only a single shell:

```bash
make test-bash  # takes less than a minute
```

[1]: https://github.com/aureliojargas/clitest/issues
[2]: https://github.com/aureliojargas/clitest/pulls
