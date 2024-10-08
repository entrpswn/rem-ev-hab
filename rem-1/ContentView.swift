//
//  ContentView.swift
//  rem-1
//
//  Created by Vova Kondriianenko on 08.10.2024.
//

import SwiftUI
import CoreGraphics

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Predefined colors
    static let lightGray = Color(hex: "BABABA")
    static let mediumGray = Color(hex: "939393")
    static let purple = Color(hex: "6F30FF")
    static let yellow = Color(hex: "FFB903")
    static let lightBlue = Color(hex: "E5E5E5")
    static let darkGray = Color(hex: "B2B2B2")
}

// MARK: - Data Models

enum TaskType {
    case event
    case task
    case habit

    var defaultIconName: String {
        switch self {
        case .event:
            return "calendar"
        case .task:
            return "square"
        case .habit:
            return "square.dotted"
        }
    }
}

struct TaskRow: Identifiable {
    let id = UUID()
    var type: TaskType
    var title: String
    var time: String?
    var disabled: Bool = false
    var highlight: Bool = false
    var iconColor: Color?
    var isCompleted: Bool = false
    var customIconName: String?
}

enum SectionType {
    case events, tasks, habits

    var headerTitle: String {
        switch self {
        case .events:
            return "Schedule"
        case .tasks:
            return "Tasks"
        case .habits:
            return "Habits"
        }
    }
}

struct DataSection: Identifiable {
    let id = UUID()
    let type: SectionType
    var items: [TaskRow]
}

// MARK: - ContentView

struct ContentView: View {
    @State private var showingSheet = false
    @State private var sections: [DataSection] = [
        DataSection(type: .events, items: [
            TaskRow(type: .event, title: "Wake up", time: "09:00", iconColor: .yellow, customIconName: "sun.max.fill"),
            TaskRow(type: .event, title: "Design Crit", time: "10:00", iconColor: .lightBlue),
            TaskRow(type: .event, title: "Haircut with Vincent", time: "13:00", iconColor: .lightBlue),
            TaskRow(type: .event, title: "Birthday party", time: "18:30", iconColor: .lightBlue),
            TaskRow(type: .event, title: "Wind down", time: "21:00", iconColor: .purple, customIconName: "moon.fill")
        ]),
        DataSection(type: .tasks, items: [
            TaskRow(type: .task, title: "Finish designs"),
            TaskRow(type: .task, title: "Make pasta")
        ]),
        DataSection(type: .habits, items: [
            TaskRow(type: .habit, title: "Pushups ×100")
        ])
    ]
    @State private var editingItemId: UUID?

    var body: some View {
        VStack(spacing: 0) { // Changed from ZStack to VStack
            content
            addButton
        }
        .sheet(isPresented: $showingSheet) {
            AddItemSheet(
                onAddTask: { addNewTask() },
                onAddHabit: { addNewHabit() }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.hidden)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            taskList
        }
    }

    private var header: some View {
        HStack {
            Text("08")
                .font(.system(size: 56, weight: .bold))

            Spacer()

            VStack(alignment: .trailing) {
                Text("October '24")
                    .font(.headline)
                    .foregroundColor(.lightGray)
                Text("Tuesday")
                    .font(.subheadline)
                    .foregroundColor(.lightGray)
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 20)
        .padding(.bottom, 20) // Adjusted bottom padding
        .background(Color(UIColor.systemBackground))
    }

    private var taskList: some View {
        List {
            ForEach(sections.indices, id: \.self) { sectionIndex in
                let section = sections[sectionIndex]
                Section(
                    header: Text(section.type.headerTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                ) {
                    ForEach(section.items.indices, id: \.self) { itemIndex in
                        let item = section.items[itemIndex]
                        let itemBinding = Binding<TaskRow>(
                            get: { self.sections[sectionIndex].items[itemIndex] },
                            set: { self.sections[sectionIndex].items[itemIndex] = $0 }
                        )

                        EditableTaskRow(task: itemBinding, isEditing: editingItemId == item.id) {
                            editingItemId = (editingItemId == item.id) ? nil : item.id
                        }
                        
                        .swipeActions(edge: .trailing) {
                            if item.type == .task || item.type == .habit {
                                Button(role: .destructive) {
                                    deleteItem(itemId: item.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .listRowSeparator(.hidden) // Hide default separator if using custom divider
                        .listRowInsets(EdgeInsets(top: 0, leading: 28, bottom: 0, trailing: 28))
                        .listRowBackground(Color(UIColor.systemBackground))

                        // Add custom divider except for the last item
                        if itemIndex < section.items.count - 1 {
                            DottedDivider()
                        }
                    }
                }
                .textCase(nil)
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.systemBackground))
    }

    private var addButton: some View {
        Button(action: {
            showingSheet = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.mediumGray)
                .frame(width: 90, height: 60)
        }
        .background(Color(hex: "F5F5F5").opacity(0.9))
        .cornerRadius(30)
        .padding(.top, 8)
    }

    // MARK: - Functions

    func addNewTask() {
        if let index = sections.firstIndex(where: { $0.type == .tasks }) {
            let newTask = TaskRow(type: .task, title: "")
            sections[index].items.insert(newTask, at: 0)
            editingItemId = newTask.id
            showingSheet = false
        }
    }

    func addNewHabit() {
        if let index = sections.firstIndex(where: { $0.type == .habits }) {
            let newHabit = TaskRow(type: .habit, title: "")
            sections[index].items.insert(newHabit, at: 0)
            editingItemId = newHabit.id
            showingSheet = false
        }
    }

    func deleteItem(itemId: UUID) {
        for sectionIndex in sections.indices {
            if let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.id == itemId }) {
                sections[sectionIndex].items.remove(at: itemIndex)
                break
            }
        }
    }
}

// MARK: - AddItemSheet

struct AddItemSheet: View {
    var onAddTask: () -> Void
    var onAddHabit: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add new")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.mediumGray)
                }
            }
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)

            // Content with styled buttons
            VStack(spacing: 12) {
                Button(action: {
                    onAddTask()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "square")
                            .font(.system(size: 20))
                            .foregroundColor(.primary).opacity(0.2)
                        Text("Task")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }

                Button(action: {
                    onAddHabit()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "square.dotted")
                            .font(.system(size: 20))
                            .foregroundColor(.primary).opacity(0.2)
                        Text("Habit")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)

            Spacer()
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - EditableTaskRow

struct EditableTaskRow: View {
    @Binding var task: TaskRow
    var isEditing: Bool
    var onCommit: () -> Void
    @State private var isChecked: Bool = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        HStack {
            if task.type == .task || task.type == .habit {
                Toggle(isOn: $isChecked.animation(.spring())) {
                    EmptyView()
                }
                .toggleStyle(CheckboxStyle(isDotted: task.type == .habit))
                .onChange(of: isChecked) { newValue in
                    withAnimation {
                        task.isCompleted = newValue
                    }
                }
            } else {
                Image(systemName: task.customIconName ?? task.type.defaultIconName)
                    .font(.system(size: 24))
                    .frame(width: 30, height: 30)
                    .foregroundColor(task.iconColor ?? .blue)
            }

            if isEditing {
                TextField("Enter title", text: $task.title, onCommit: {
                    onCommit()
                    isFieldFocused = false
                })
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16, weight: .semibold))
                .focused($isFieldFocused)
                .onAppear {
                    isFieldFocused = true
                }
            } else {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .strikethrough(task.isCompleted, color: .darkGray)
                    .foregroundColor(task.isCompleted ? .darkGray : (task.disabled ? .lightGray : .primary))
                    .onTapGesture {
                        onCommit()
                    }
            }

            Spacer()

            if let time = task.time {
                Text(time)
                    .foregroundColor(.lightGray)
            }
        }
        .frame(height: 40) // Set a fixed height for the row
        .opacity(task.disabled ? 0.5 : 1.0)
        .padding(.vertical, 1) //adjust padding for list items
        .onAppear {
            isChecked = task.isCompleted
        }
    }
}

// MARK: - CheckboxStyle

struct CheckboxStyle: ToggleStyle {
    var isDotted: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : (isDotted ? "square.dotted" : "square"))
                .frame(width: 30, height: 30)
                .foregroundColor(configuration.isOn ? .blue : .lightBlue)
                .font(.system(size: 24, weight: .semibold))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
        }
    }
}

// MARK: - DottedDivider

struct DottedDivider: View {
    var lineWidth: CGFloat = 1
    var lineCap: CGLineCap = .butt
    var dash: [CGFloat] = [2, 3]
    var dashPhase: CGFloat = 0
    var color: Color = Color.lightGray.opacity(0.2)
    var padding: CGFloat = 12

    var body: some View {
        Rectangle()
            .frame(height: lineWidth)
            .foregroundColor(.clear)
            .overlay(
                Rectangle()
                    .stroke(style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: lineCap,
                        dash: dash,
                        dashPhase: dashPhase
                    ))
                    .foregroundColor(color)
            )
            .padding(.horizontal, padding)
    }
}
// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
