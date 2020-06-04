from libraryTemplateGenerate import LibraryTemplate
from Path import Path
from mainPageTemplateGenerate import MainPageTemplate
from fuzzerTemplateGenerate import FuzzerTemplate
from plotGenerator import Plots
import os
import sys
import json


def main():

    # We initialize a few constants for the different directories
    TEMPLATES = "templates"
    OUTPUTS = "outputs"
    PLOTS = "plots"
    TABLES = "tables"
    LIBRARIES = "libraries"
    FUZZERS = "fuzzers"

    # We get the current path to the file
    current_path = os.path.dirname(__file__)

    # Set paths for templates, output and images
    output_dir = os.path.join(current_path, OUTPUTS)
    fuzzers_dir = os.path.join(output_dir, FUZZERS)
    libraries_dir = os.path.join(output_dir, LIBRARIES)
    template_dir = os.path.join(current_path, TEMPLATES)

    # These path should be set according to where the html file will be saved
    plot_dir = os.path.join(output_dir, PLOTS)
    tables_dir = os.path.join(output_dir, TABLES)

    # We get the json
    json_data = get_data()

    path = Path(template_dir, libraries_dir, tables_dir, plot_dir)

    print("Create useful directories")
    path.create_directories()

    print("Generate plots")
    plots = Plots(json_data, path)
    plots.generate()

    libraries, fuzzers = plots.get_all_targets_and_fuzzers()

    fuzzer_template = FuzzerTemplate(Path(template_dir, fuzzers_dir, tables_dir, "../"+PLOTS), libraries)

    print("Create library pages")
    library_template = LibraryTemplate(Path(template_dir, libraries_dir, tables_dir, "../"+PLOTS))
    for library in libraries:
        library_template.render("library_template.html", library+".html")

    print("Create main page")
    main_template = MainPageTemplate(Path(template_dir, output_dir, tables_dir, "./"+PLOTS), fuzzers, libraries)
    main_template.render("report_template.html", "report.html")

    print("Create fuzzer pages")
    for fuzzer in fuzzers:
        fuzzer_template.render("fuzzer_template.html", fuzzer+".html")


def get_data():
    if(len(sys.argv) == 1):
        raise Exception("The program need a json as the first argument")

    print("Load json")
    with open(sys.argv[1]) as f:
        return json.load(f)


main()
