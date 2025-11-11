#- GitHub- Pages- Setup- for- OptiPlant.jl

##- To- configure- documentation- on- GitHub- Pages:

###- 1.- Enable- GitHub- Pages- in- the- repository

1.- Go- to- your- repository- on- GitHub:- `https://github.com/SebastianBanda1/OptiPlant`
2.- Go- to- **Settings**- >- **Pages**
3.- Under- **Source**,- select- **GitHub- Actions**
4.- Documentation- will- deploy- automatically- when- you- push- to- `main`- or- `Development`- branches

###- 2.- Documentation- URLs

Once- GitHub- Pages- is- configured,- documentation- will- be- available- at:

-- **Stable**:- `https://sebastianbanda1.github.io/OptiPlant/stable/`
-- **Latest**:- `https://sebastianbanda1.github.io/OptiPlant/latest/`
-- **Root**:- `https://sebastianbanda1.github.io/OptiPlant/`- (redirects- to- stable)

###- 3.- Automatic- workflow

The- `.github/workflows/docs.yml`- file- is- configured- to:
-- Build- documentation- automatically- on- push/PR
-- Deploy- to- GitHub- Pages- when- `main`- or- `Development`- is- updated
-- Create- `stable`- and- `latest`- versions- of- documentation

###- 4.- Final- structure

```
OptiPlant/
├──- .github/workflows/docs.yml- - - - #- Workflow- for- automatic- deployment
├──- docs/
│- - - ├──- make.jl- - - - - - - - - - - - - - - - - - - #- Build- script
│- - - ├──- Project.toml- - - - - - - - - - - - - - #- Documentation- dependencies
│- - - └──- src/
│- - - - - - - ├──- index.md- - - - - - - - - - - - - - #- Main- page
│- - - - - - - ├──- installation.md- - - - - - - #- Installation- guide
│- - - - - - - ├──- usage.md- - - - - - - - - - - - - - #- Usage- guide
│- - - - - - - ├──- Examples.md- - - - - - - - - - - #- Practical- examples
│- - - - - - - └──- api.md- - - - - - - - - - - - - - - #- API- reference
└──- README.md- - - - - - - - - - - - - - - - - - - - - #- Documentation- links
```

###- 5.- To- update- documentation

1.- Edit- files- in- `docs/src/`
2.- Commit- and- push- to- `Development`- or- `main`
3.- GitHub- Actions- will- build- and- deploy- automatically
4.- Documentation- will- be- available- in- a- few- minutes

###- 6.- Local- verification

To- test- locally- before- pushing:

```bash
cd- OptiPlant
julia- --project=docs- docs/make.jl
cd- docs/build
python- -m- http.server- 8000
#- Open- http://localhost:8000- in- your- browser
```
