import os
import pandas


conda_env = 'envs/muon.yml'
datasets = pandas.read_csv('input/samples.csv', header=None).loc[:, 0].tolist()[1:]
metrics = ['n_genes_by_counts', 'total_counts', 'pct_counts_mt', 'pct_counts_rb', 'doublet_score']



rule all:
    input:
        'objects/05_merged_filtered_integrated_clustered_anndata_object.h5ad'


rule preprocess:
    input:
        cellbender='data/{dataset}/cellbender_gex_counts_filtered.h5'
    output:
        anndata='objects/01_{dataset}_anndata_object.h5ad'
    conda:
        conda_env
    params:
        sample='{dataset}'
    script:
        'scripts/main/preprocess.py'

rule plot_metrics:
    input:
        objects=expand('objects/01_{dataset}_anndata_object.h5ad', dataset=datasets)
    output:
        anndata='objects/02_merged_anndata_object.h5ad',
        plots=expand('plots/violin_{metric}.png', metric=metrics)
    conda:
        conda_env
    params:
        metrics=metrics
    script:
        'scripts/main/plot_metrics.py'

rule filter:
    input:
        anndata='objects/02_merged_anndata_object.h5ad'
    output:
        anndata='objects/03_merged_filtered_anndata_object.h5ad'
    conda:
        conda_env
    script:
        'scripts/main/filter.py'
    
rule scvi:
    input:
        anndata='objects/03_merged_filtered_anndata_object.h5ad'
    output:
        anndata='objects/04_merged_filtered_integrated_anndata_object.h5ad'
    conda:
        conda_env
    params:
        latent_key='X_scvi'
    script:
        'scripts/main/scvi.py'

rule cluster:
    input:
        anndata='objects/04_merged_filtered_integrated_anndata_object.h5ad'
    output:
        anndata='objects/05_merged_filtered_integrated_clustered_anndata_object.h5ad'
    conda:
        conda_env
    params:
        latent_key='X_scvi'
    script:
        'scripts/main/clustering_umap.py'