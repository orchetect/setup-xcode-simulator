# setup-xcode-simulator

This action is intended to dynamically find the best available pre-installed Xcode device simulator for macOS images in GitHub Actions.

## Motivation

Relevant Xcode device simulator names and platform versions are an ever-moving hamster wheel. In order to maintain GitHub Actions CI pipelines across dozens of open-source repositories, over the years I have gradually tweaked and refined scripts to aid in this process. 

Over time, numerous quirks and edge cases of both GitHub actions runners and how Xcode behaves has led to a laundry list of steps involved in successfully preparing a device simulator for use on runners.

This acton is designed as a one-stop shop to select and prepare a device simulator, primarily with the intention of running unit tests on the simulator.

## Input Parameters

| Name             | Required | Description                                                  | Format                       |
| ---------------- | -------- | ------------------------------------------------------------ | ---------------------------- |
| `refresh`        | No       | Refresh Xcode simulators by first calling the simulator controller to refresh by listing all local simulators. | `true` or `false`            |
| `download`       | No       | Asks the simulator controller to first download a relevant simulator for the platform specified by the target parameter. | `true` or `false`            |
| `workspace-path` | No       | Relative Xcode workspace path. If the target is a Swift Package that exists in the root of the repository, omit this parameter. | Relative path from repo root |
| `scheme`         | Yes      | Xcode scheme name that will be used when enumerating available device simulators. | String                       |
| `target`         | Yes      | Target identifier (case-insensitive). See table below for full list of identifiers. | String                       |
| `os-version`     | No       | Platform OS version (regular expression).                    | String                       |

Target identifiers supported, with tables listed in increasing degree of specificity:

| Target  | Device Family | OS Version                                 |
| ------ | -------- | ------------------------------------------------------- |
| `iOS`  | Newest iPhone simulator | Newest OS version, unless specified |
| `tvOS` | Newest Apple TV simulator | Newest OS version, unless specified |
| `watchOS` | Newest Apple Watch simulator | Newest OS version, unless specified |
| `visionOS` | Newest Vision Pro simulator | Newest OS version, unless specified |

| Target  | Platform | Device Family                                           | OS Version |
| ------ | -------- | ------------------------------------------------------- | ------ |
| `iphone` | iOS | Newest iPhone simulator | Newest OS version, unless specified |
| `ipad` | iOS | Newest iPad simulator | Newest OS version, unless specified |
| `tv` | tvOS | Newest Apple TV simulator | Newest OS version, unless specified |
| `watch` | watchOS | Newest Apple Watch simulator | Newest OS version, unless specified |
| `visionpro` | visionOS | Newest Vision Pro simulator | Newest OS version, unless specified |

| Target  | Platform | Device Family                                           | OS Version |
| ------ | -------- | ------------------------------------------------------- | ------ |
| `iphone-air` | iOS | Newest iPhone Air simulator | Newest OS version, unless specified |
| `iphone-pro` | iOS | Newest iPhone Pro simulator | Newest OS version, unless specified |
| `iphone-pro-max` | iOS | Newest iPhone Pro Max simulator | Newest OS version, unless specified |
| `ipad-air` | iOS | Newest iPad Air simulator | Newest OS version, unless specified |
| `ipad-mini` | iOS | Newest iPad mini simulator | Newest OS version, unless specified |
| `ipad-pro` | iOS | Newest iPad Pro simulator | Newest OS version, unless specified |
| `tv-4k` | tvOS | Newest Apple TV 4K simulator | Newest OS version, unless specified |
| `watch-se` | watchOS | Newest Apple Watch SE simulator | Newest OS version, unless specified |
| `watch-series` | watchOS | Newest Apple Watch Series simulator | Newest OS version, unless specified |

## Output Parameters

The action outputs the following parameters:

| Name                   | Description                                                  | Example                                |
| ---------------------- | ------------------------------------------------------------ | -------------------------------------- |
| `id`       | Verbatim simulator ID, usable in `xcodebuild test` destination. | `17FC425F-F336-48DC-8D5A-05DA7BCF7B7D` |
| `platform` | Verbatim platform name, usable in `xcodebuild test` destination. | `iOS Simulator`                        |
| `platform-short`       | Short platform name, usable in `xcodebuild build` generic destinations. | `iOS`                                  |
| `workspace-path`       | Xcode workspace path relative to repo root | `Foo/Foo.xcodeproj/project.xcworkspace` |

## Usage

Prepare an iOS device simulator (defaults to iPhone)

- using the latest available device and latest available OS version
- to test a Swift Package

```yaml
jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: orchetect/setup-xcode-simulator@v1
      with:
        scheme: MySchemeName
        target: iOS
```

Prepare an iOS device simulator (defaults to iPhone)

- running iOS 26.2
- to test a Swift Package

```yaml
jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: orchetect/setup-xcode-simulator@v1
      with:
        scheme: MySchemeName
        target: iOS
        os-version: 26.2
```

Prepare an iOS device simulator using the latest iPhone Pro Max device 

- running the latest available version of iOS 18
- to test a Swift Package

```yaml
jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: orchetect/setup-xcode-simulator@v1
      with:
        scheme: MySchemeName
        target: iphone-pro-max
        os-version: 18.*
```

Prepare an iOS device simulator (defaults to iPhone)

- using the latest available device and latest available OS version
- to test an Xcode project named `MyProject.xcodeproj` located within the `MyProject` folder

```yaml
jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: orchetect/setup-xcode-simulator@v1
      with:
        workspace-path: MyProject/MyProject.xcodeproj/project.xcworkspace
        scheme: MySchemeName
        target: iOS
```

## Complete Examples

### Build and Test a Swift Package for iOS

Prepare an iOS device simulator (defaults to iPhone) using the latest device and operating system version in order to test a Swift Package. Beforehand, refresh simulators and download an appropriate simulator if one is not yet installed.

> [!TIP]
>
> Separating the build and test phases into separate steps is recommended for organization and clarity.
>
> Building (unlike testing) typically does not require a simulator destination and a generic destination can be supplied.

```yaml
env:
  SCHEME: "MySchemeName"
  
jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@main
    - name: Prepare Device Simulator
      id: sim-setup
      uses: orchetect/setup-xcode-simulator@v1
      with:
        refresh: true
        download: true
        scheme: ${{ env.SCHEME }}
        target: iOS
    - name: Build
      run: |
        xcodebuild build \
          -workspace "$WORKSPACEPATH" \
          -scheme "$SCHEME" \
          -destination "generic/platform=$PLATFORMSHORT"
      env:
        PLATFORMSHORT: ${{ steps.sim-setup.outputs.platform-short }}
        WORKSPACEPATH: ${{ steps.sim-setup.outputs.workspace-path }}
    - name: Unit Test
      run: |
        xcodebuild test \
          -workspace "$WORKSPACEPATH" \
          -scheme "$SCHEME" \
          -destination "platform=$PLATFORM,id=$ID"
      env:
        ID: ${{ steps.sim-setup.outputs.id }}        
        PLATFORM: ${{ steps.sim-setup.outputs.platform }}
        WORKSPACEPATH: ${{ steps.sim-setup.outputs.workspace-path }}
```

### Build and Test a Swift Package for Multiple Platforms

Set up a matrix of jobs for iOS, tvOS, watchOS and visionOS to prepare a device simulator  using the latest device and operating system version in order to test a Swift Package. Beforehand, refresh simulators and download an appropriate simulator if one is not yet installed.

> [!TIP] 
>
> Separating the build and test phases into separate steps is recommended for organization and clarity.
>
> Building (unlike testing) typically does not require a simulator destination and a generic destination can be supplied.

```yaml
env:
  SCHEME: "MySchemeName"
  
jobs:
  build:
    runs-on: macos-latest
    strategy:
      matrix:
        target: [iOS, tvOS, watchOS, visionOS]
    continue-on-error: true
    steps:
    - uses: actions/checkout@main
    - name: Prepare Device Simulator
      id: sim-setup
      uses: orchetect/setup-xcode-simulator@v1
      with:
        refresh: true
        download: true
        scheme: ${{ env.SCHEME }}
        target: ${{ matrix.target }}
    - name: Build
      run: |
        xcodebuild build \
          -workspace "$WORKSPACEPATH" \
          -scheme "$SCHEME" \
          -destination "generic/platform=$PLATFORMSHORT"
      env:
        PLATFORMSHORT: ${{ steps.sim-setup.outputs.platform-short }}
        WORKSPACEPATH: ${{ steps.sim-setup.outputs.workspace-path }}
    - name: Unit Test
      run: |
        xcodebuild test \
          -workspace "$WORKSPACEPATH" \
          -scheme "$SCHEME" \
          -destination "platform=$PLATFORM,id=$ID"
      env:
        ID: ${{ steps.sim-setup.outputs.id }}        
        PLATFORM: ${{ steps.sim-setup.outputs.platform }}
        WORKSPACEPATH: ${{ steps.sim-setup.outputs.workspace-path }}
```

## Documentation

This README serves as basic documentation.

## Author

Coded by a bunch of 🐹 hamsters in a trenchcoat that calls itself [@orchetect](https://github.com/orchetect).

## License

Licensed under the MIT license. See [LICENSE](https://github.com/orchetect/setup-xcode-simulator/blob/main/LICENSE) for details.

## Community & Support

Please do not email maintainers for technical support. Several options are available for issues and questions:

- Questions and feature ideas can be posted to [Discussions](https://github.com/orchetect/setup-xcode-simulator/discussions).
- If an issue is a verifiable bug with reproducible steps it may be posted in [Issues](https://github.com/orchetect/setup-xcode-simulator/issues).

## Contributions

Contributions are welcome. Posting in [Discussions](https://github.com/orchetect/setup-xcode-simulator/discussions) first prior to new submitting PRs for features or modifications is encouraged.
