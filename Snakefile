import glob
configfile: "config.yaml"
localrules: create_opt_folders,extract_Z,plan_optimized,create_folder,collect_optimization_ratio,collect_optimization_parameters,collect_runs_observable,create_folder,create_run_folders


checkpoint create_opt_folders:
    input:
        ["sims.dat"]
    output:
        directory( "{root_dir}/opt" )
    conda:
        "py3.yml"
    script:
        "scripts/create_opt_folders.py"


checkpoint create_run_folders:
    input:
        "{root_dir}/opt"
    output:
        directory("{root_dir}/run")
    conda:
        "py3.yml"
    params:
        nChains=10
    script:
        "scripts/create_run_folders.py"

rule create_folder:
    input:
        [ "{folder}/parameters.dat" ]
    output:
        ["{folder}/input.json"]
    conda:
        "py3.yml"
    script:
        "scripts/create_folder.py"


rule run_opt_folder:
    input:
        "{folder}/input.json"
    output:
        ["{folder}/ratio.dat","{folder}/energy.dat","{folder}/eV.dat"]
    wildcard_constraints:
        folder=expand("{root_dir}/opt/.*",root_dir=config["root_dir"])[0]
    resources:
        time="00-01:00:00",name=expand("opt-{name}",name=config["name"])[0]
    retries: 3

    shell:
        "cd {wildcards.folder};module load Boost;rm -f *.hdf5;module load HDF5;rm -f energy.dat;rm -f eV.dat;~/qmc/build-3D/pimc/pimc input.json >  pimc.out"    


rule run_run_folder:
    input:
        "{folder}/input.json"
    output:
        ["{folder}/ratio.dat","{folder}/energy.dat","{folder}/eV.dat","{folder}/M.dat"]
    wildcard_constraints:
        folder=expand("{root_dir}/run/.*", root_dir=config["root_dir"] )[0]
    resources:
        time="02-00:00:00",name=expand("run-{name}",name=config["name"])[0]
    retries: 3
    shell:
        "cd {wildcards.folder};module load Boost;rm -f *.hdf5;module load HDF5;rm -f energy.dat;rm -f eV.dat;rm -f M.dat;~/qmc/build-3D/pimc/pimc input.json >  pimc.out"


def getFiles(folder,name):
    files=[]
    for folder_dir in os.listdir(folder) :
        if not folder_dir.startswith('.') and os.path.isdir(os.path.join(folder,folder_dir)):
                    files.append(os.path.join(folder,folder_dir,name))
    return (files)


rule collect_optimization_ratio:
    input:
        lambda wildcards: getFiles( "{}/opt/{}".format(config["root_dir"],wildcards.folder),"ratio.dat")
    output:
        "{root_dir}/opt/{folder}/collect_ratio.dat"
    
    script:
        "scripts/gather.py"


rule collect_optimization_parameters:
    input:
        lambda wildcards: getFiles("{}/opt/{}".format(config["root_dir"],wildcards.folder),"parameters.dat")
    output:
        "{root_dir}/opt/{folder}/parameters.dat"
    params:
        merge_parameters=False
    script:
        "scripts/gather.py"

rule extract_Z:
    input: 
        "{folder}/collect_ratio.dat"
    output:
        ["{folder}/Z.dat","{folder}/Z_extrap.dat"]
    script:
        "scripts/optimization-twoComponent.R"


rule plan_optimized:
    input:
        [ "{root_dir}/opt/{folder}/Z.dat" , "{root_dir}/opt/{folder}/parameters.dat" ]
    output:
        "{root_dir}/run/{folder}/run{it}/parameters.dat"
    wildcard_constraints:
        it="[0-9]+"

    script:
        "scripts/plan_optimized.py"



def getFilesFirstLevel(folder,name):
    files=[]
    for folder_dir in os.listdir(folder):
        if not folder_dir.startswith('.')  and os.path.isdir(os.path.join(folder,folder_dir)):
            for sub_dir in os.listdir(os.path.join(folder,folder_dir)):
                if not sub_dir.startswith('.') and os.path.isdir(os.path.join(folder,folder_dir,sub_dir)):

                    files.append(os.path.join(folder,folder_dir,sub_dir,name))
    return (files)

rule collect_runs_observable:
    input:
        lambda wildcards: getFilesFirstLevel( "{}/run".format(wildcards.root_dir),"{}.dat".format(wildcards.observable))
    output:
        "{root_dir}/agg/{observable}.dat"
    script:
        "scripts/gather.py"