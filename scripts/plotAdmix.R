args <- commandArgs(TRUE)
infile <- args[1]
info <- args[2]

pdf(file=paste(infile,".pdf", sep =""))
pdf(file="isophya_admxiture_altd_new.pdf")

# Read the population and admixture data
pop <- read.table(info, header = FALSE, as.is = TRUE)
admix <- t(as.matrix(read.table(infile)))

# Specify the desired population order
desired_order <- c("450", "850", "900", "1000", "1100", "1200", "1300", "1900", "2000", "2100", "2300")

# Print the unique population names in your data
print("Unique population names in data:")
print(unique(pop$V1))

# Create a factor with levels in the desired order
pop$V1 <- factor(pop$V1, levels = desired_order)

# Check if there are any NA values after converting to factor
if (any(is.na(pop$V1))) {
  print("The following population names in your data do not match the specified order:")
  print(unique(pop$V1[is.na(pop$V1)]))
}

# Order the population data according to the specified order
pop <- pop[order(pop$V1), ]
admix <- admix[, order(pop$V1)]

# Plot the admixture data
isoPalette = c("#000000", "#009E73")
h <- barplot(admix, col = isoPalette, las = 2, space = 0, border = NA, xlab = "Individuals", ylab = "admixture")
text(tapply(1:nrow(pop), pop$V1, mean), -0.07, unique(pop$V1), xpd = TRUE, srt = -90)
abline(v = c(5,12,19,26,33,40,47,54,61,67,74,81), lty = 2, col = "white")

unlink("Rplots.pdf", force = TRUE)
dev.off()

