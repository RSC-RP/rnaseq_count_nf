nextflow.enable.dsl = 2
params.sample_sheet = "test_data/sample_sheet.txt"


include { FASTQC } from './modules/nf-core/modules/fastqc/main'

meta_fq_ch = Channel.fromPath(file(params.sample_sheet))
				.splitCsv(header: true, sep: '\t')
				.map { sample -> [sample["Sample"] + "_", file(sample["R1"]), file(sample["R2"])]}

fqs_ch = Channel.fromPath(file(params.sample_sheet))

