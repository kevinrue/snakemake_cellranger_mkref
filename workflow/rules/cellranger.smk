from snakemake.remote.FTP import RemoteProvider as FTPRemoteProvider
FTP = FTPRemoteProvider()

rule genome:
    input:
        FTP.remote(config['genome'])
    output:
        'resources/genome.fa.gz'
    log:
    	'resources/genome.log'
    shell:
        '''
        mv {input} {output} 2> {log}
        '''


rule genesets:
    input:
        FTP.remote(config['genesets'])
    output:
        'resources/genesets.gtf.gz'
    log:
    	'resources/genome.log'
    shell:
        '''
        mv {input} {output} 2> {log}
        '''
      

def get_local_memory():
    '''
    Get cellranger mkref memory options.
    '''
    memory_per_cpu = config['mkref']['memory_per_cpu']
    threads = config['mkref']['threads']
    
    memory_value = memory_per_cpu * threads
    
    return memory_value


rule cellranger_mkref:
    input:
        fasta='resources/genome.fa.gz',
        genes='resources/genesets.gtf'
    output:
        directory("resources/cellranger_index")
    params:
        memory=get_local_memory(),
        threads=config['mkref']['threads']
    envmodules:
        "bio/cellranger/3.1.0"
    threads: config['mkref']['threads']
    resources:
        mem_free_gb=config['mkref']['memory_per_cpu']
    log:
        err="results/logs/cellranger_mkref.err",
        out="results/logs/cellranger_mkref.out",
    shell:
        """
        gunzip -c {input.genes} > {input.genes}.tmp &&
        gunzip -c {input.fasta} > {input.fasta}.tmp &&
        cellranger mkref \
        --genome=cellranger_index \
        --fasta="{input.fasta}.tmp" \
        --genes="{input.genes}.tmp" \
        --nthreads={params.threads} \
        --memgb={params.memory}
        2> {log.err} > {log.out} &&
        mv cellranger_index {output} &&
        rm {input.genes}.tmp {input.fasta}.tmp
        """
