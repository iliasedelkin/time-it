import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TaskRecord.startedAt, order: .reverse)
    private var records: [TaskRecord]

    @State private var viewModel = HistoryViewModel()
    @State private var showExportOptions = false

    private var filteredRecords: [TaskRecord] {
        viewModel.filteredRecords(from: records)
    }

    private var exportErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.exportErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.exportErrorMessage = nil
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker(L10n.historyFilterLabel, selection: $viewModel.selectedFilter) {
                ForEach(HistoryViewModel.Filter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.selectedFilter == .customRange {
                HStack(spacing: 12) {
                    DatePicker(
                        L10n.historyStartDateLabel,
                        selection: $viewModel.customStartDate,
                        displayedComponents: .date
                    )

                    DatePicker(
                        L10n.historyEndDateLabel,
                        selection: $viewModel.customEndDate,
                        displayedComponents: .date
                    )
                }
            }

            if filteredRecords.isEmpty {
                VStack {
                    Spacer()
                    Text(L10n.historyEmptyState)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(filteredRecords) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.primaryLine(for: record))
                        Text(viewModel.secondaryLine(for: record))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }
        }
        .padding(16)
        .navigationTitle(L10n.historyTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .help(L10n.cancelButton)
            }

            ToolbarItem(placement: .principal) {
                Text(L10n.historyTitle)
                    .font(.headline)
            }

            ToolbarItem(placement: .automatic) {
                Button(L10n.exportButton) {
                    showExportOptions = true
                }
                .disabled(filteredRecords.isEmpty)
            }
        }
        .confirmationDialog(
            L10n.exportDialogTitle,
            isPresented: $showExportOptions,
            titleVisibility: .visible
        ) {
            Button(L10n.exportTXTOption) {
                viewModel.export(records: filteredRecords, format: .txt)
            }

            Button(L10n.exportCSVOption) {
                viewModel.export(records: filteredRecords, format: .csv)
            }

            Button(L10n.cancelButton, role: .cancel) {}
        }
        .alert(L10n.exportErrorTitle, isPresented: exportErrorPresented) {
            Button(L10n.okButton, role: .cancel) {}
        } message: {
            Text(viewModel.exportErrorMessage ?? "")
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
}
