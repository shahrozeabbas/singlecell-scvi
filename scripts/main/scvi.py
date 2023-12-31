import scvi
import scanpy


adata = scanpy.read_h5ad(snakemake.input.anndata) # type: ignore

adata.layers['counts'] = adata.X.copy() # type: ignore
scanpy.pp.normalize_total(adata, target_sum=1e4)

scanpy.pp.log1p(adata)

adata.raw = adata

scanpy.pp.highly_variable_genes(
    adata, 
    batch_key='sample', 
    subset=True, 
    flavor='seurat_v3', 
    layer='counts', 
    n_top_genes=3000
)


noise = ['doublet_score', 'pct_counts_mt', 'pct_counts_rb']

scvi.model.SCVI.setup_anndata(adata, layer='counts', batch_key='sample', continuous_covariate_keys=noise)

model = scvi.model.SCVI(
    adata, 
    n_layers=1, 
    n_latent=50, 
    dispersion='gene',
    gene_likelihood='zinb'
)


model.train(
    train_size=0.7,
    max_epochs=1000,
    accelerator='gpu',  
    early_stopping=True,
    early_stopping_patience=40,
    plan_kwargs={'lr_factor': 0.1, 'lr_patience': 20, 'reduce_lr_on_plateau': True}
)


adata.obsm[snakemake.params.latent_key] = model.get_latent_representation() # type: ignore


adata.write_h5ad(filename=snakemake.output.anndata, compression='gzip') # type: ignore