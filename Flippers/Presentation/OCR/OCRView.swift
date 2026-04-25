import SwiftUI
import SwiftData
import PhotosUI

struct OCRView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.name) private var decks: [Deck]

    @AppStorage("ocrCloudEnhancementEnabled") private var ocrCloudEnhancementEnabled = false
    @State private var viewModel = OCRViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showNoDeckAlert = false
    @State private var showOCRProcessingNotice = false
    @State private var showCloudEnhancementConsent = false

    private var cloudEnhancementAvailability: OCRCloudEnhancementAvailability {
        OCRConfiguration.cloudEnhancementAvailability()
    }

    private var isCloudEnhancementAvailable: Bool {
        cloudEnhancementAvailability.isAvailable
    }

    private var effectiveCloudEnhancementEnabled: Bool {
        ocrCloudEnhancementEnabled && isCloudEnhancementAvailable
    }

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                Divider()

                Group {
                    switch viewModel.step {
                    case .upload:
                        uploadStep
                    case .scanning:
                        scanningStep
                    case .review:
                        reviewStep
                    case .done(let count):
                        doneStep(count: count)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("OCR 取込")
            .navigationBarTitleDisplayMode(.inline)
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("덱을 선택하지 않았습니다", isPresented: $showNoDeckAlert) {
                Button("덱 없이 저장", role: .destructive) {
                    viewModel.saveCards(context: modelContext)
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("덱 없이 저장된 카드는 나중에 덱에 연결하기 어렵습니다. 계속할까요?")
            }
            .alert("Claude 보완을 켜시겠습니까?", isPresented: $showCloudEnhancementConsent) {
                Button("켜기") {
                    ocrCloudEnhancementEnabled = true
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("이 옵션을 켜면 기기 내 OCR로 추출한 텍스트가 보안 프록시 서버를 통해 외부 AI 서비스로 전달되어 읽기와 뜻 보완에 사용될 수 있습니다. 원본 이미지는 기기 밖으로 직접 전송하지 않지만, 민감한 정보가 포함된 이미지는 업로드하지 마세요.")
            }
            .sheet(isPresented: $showOCRProcessingNotice) {
                OCRProcessingNoticeSheet()
            }
            .onAppear {
                if !isCloudEnhancementAvailable && ocrCloudEnhancementEnabled {
                    ocrCloudEnhancementEnabled = false
                }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await processImage(image)
                    }
                    photoItem = nil
                }
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        let steps = ["업로드", "스캔", "검토", "완료"]
        let currentIndex: Int = {
            switch viewModel.step {
            case .upload:   return 0
            case .scanning: return 1
            case .review:   return 2
            case .done:     return 3
            }
        }()

        return HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, label in
                HStack(spacing: 6) {
                    if index > 0 {
                        Rectangle()
                            .fill(index <= currentIndex ? Color.accentColor : Color(.systemFill))
                            .frame(width: 24, height: 2)
                    }
                    ZStack {
                        Circle()
                            .fill(index < currentIndex ? Color.accentColor :
                                  index == currentIndex ? Color.accentColor : Color(.systemFill))
                            .frame(width: 28, height: 28)
                        if index < currentIndex {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(index == currentIndex ? .white : .secondary)
                        }
                    }
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(index == currentIndex ? .primary : .secondary)
                }
            }
        }
    }

    // MARK: - Upload Step

    private var uploadStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Deck picker
            if !decks.isEmpty {
                HStack {
                    Text("저장할 덱")
                        .font(.subheadline)
                    Spacer()
                    Picker("덱 선택", selection: $viewModel.selectedDeck) {
                        Text("선택 안 함").tag(Optional<Deck>.none)
                        ForEach(decks) { deck in
                            Text(deck.name).tag(Optional(deck))
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal, 24)
            }

            cloudEnhancementSection

            // Photo picker
            PhotosPicker(selection: $photoItem, matching: .images) {
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                    Text("사진 라이브러리에서 선택")
                        .font(.headline)
                    Text("교과서, 단어장, 한자 목록 이미지\nPNG · JPG · HEIC 지원")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color(.systemFill), style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)

            // Camera button
            Button {
                if isCameraAvailable {
                    showCamera = true
                }
            } label: {
                Label("카메라로 촬영", systemImage: "camera")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!isCameraAvailable)
            .padding(.horizontal, 24)
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    showCamera = false
                    Task {
                        await processImage(image)
                    }
                }
            }

            if !isCameraAvailable {
                Text("현재 기기에서는 카메라를 사용할 수 없습니다. 사진 라이브러리에서 이미지를 선택하세요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("현재 인식에 잘 맞는 형식", systemImage: "info.circle")
                    .font(.footnote.weight(.semibold))
                Text("단어, 읽기, 뜻이 좌우 열로 비교적 또렷하게 정렬된 이미지에서 가장 정확합니다. 자유로운 문단형 문서나 복잡한 표는 일부 누락될 수 있습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private var cloudEnhancementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Claude 읽기/뜻 보완", systemImage: "sparkles.rectangle.stack")
                        .font(.subheadline.weight(.semibold))
                    Text("기본값은 로컬 OCR만 사용합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: cloudEnhancementBinding)
                    .labelsHidden()
                    .disabled(!isCloudEnhancementAvailable)
            }

            Text(cloudEnhancementDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("처리 방식 보기") {
                showOCRProcessingNotice = true
            }
            .font(.footnote.weight(.semibold))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    private var cloudEnhancementBinding: Binding<Bool> {
        Binding(
            get: { ocrCloudEnhancementEnabled },
            set: { newValue in
                if newValue {
                    showCloudEnhancementConsent = true
                } else {
                    ocrCloudEnhancementEnabled = false
                }
            }
        )
    }

    private var cloudEnhancementDescription: String {
        if case .unavailable(let reason) = cloudEnhancementAvailability {
            return "사용 불가: \(reason)"
        }
        if effectiveCloudEnhancementEnabled {
            return "켜짐: 기기 내 OCR로 추출한 텍스트가 보안 프록시 서버를 통해 외부 AI 서비스로 전달되어 읽기와 뜻 보완에 사용될 수 있습니다."
        }
        return "꺼짐: 기기 내 Vision OCR만 사용합니다. 읽기/뜻은 일부 비어 있을 수 있습니다."
    }

    private func processImage(_ image: UIImage) async {
        await viewModel.processImage(
            image,
            useCloudEnhancement: effectiveCloudEnhancementEnabled
        )
    }

    // MARK: - Scanning Step

    private var scanningStep: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.8)
            Text(viewModel.scanningMessage)
                .font(.headline)
                .padding(.top, 12)
                .animation(.easeInOut, value: viewModel.scanningMessage)
            Text("이미지 크기에 따라 최대 15초 소요됩니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Review Step

    private var reviewStep: some View {
        VStack(spacing: 0) {
            if let warning = viewModel.enhancementWarning {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(warning)
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        viewModel.enhancementWarning = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.12))
            }

            if let notice = viewModel.reviewNoticeMessage {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.10))
            }

            HStack {
                Text("\(viewModel.selectedWordCount)개 선택 / \(viewModel.extractedWords.count)개 추출")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("전체 선택") { viewModel.selectAll() }
                    .font(.subheadline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            if viewModel.hasInvalidSelectedWords {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                    Text("선택 항목 중 한자·읽기·뜻이 비어 있는 행은 저장할 수 없습니다. 내용을 입력하거나 선택 해제하세요.")
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.12))
            }

            if viewModel.extractedWords.isEmpty {
                ContentUnavailableView(
                    "단어 없음",
                    systemImage: "text.magnifyingglass",
                    description: Text("이미지에서 일본어 단어를 찾지 못했습니다. 현재 OCR은 가로형 일본어 단어표 레이아웃에 가장 잘 맞습니다.")
                )
            } else {
                List {
                    ForEach($viewModel.extractedWords) { $word in
                        OCRWordRow(word: $word)
                    }
                }
                .listStyle(.plain)
            }

            Divider()

            Button {
                if viewModel.selectedDeck == nil {
                    showNoDeckAlert = true
                } else {
                    viewModel.saveCards(context: modelContext)
                }
            } label: {
                Label(
                    "\(viewModel.savableSelectedWordCount)개 카드 생성",
                    systemImage: "plus.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    viewModel.savableSelectedWordCount == 0 || viewModel.hasInvalidSelectedWords
                    ? Color(.systemFill) : Color.accentColor,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .foregroundStyle(
                    viewModel.savableSelectedWordCount == 0 || viewModel.hasInvalidSelectedWords
                    ? Color.secondary : .white
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.savableSelectedWordCount == 0 || viewModel.hasInvalidSelectedWords)
            .padding(20)
        }
    }

    // MARK: - Done Step

    private func doneStep(count: Int) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("カード作成完了！")
                .font(.largeTitle.bold())
            Text("\(count)개의 카드가 생성되었습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                viewModel.reset()
            } label: {
                Label("추가 스캔", systemImage: "arrow.counterclockwise")
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Text("카드 탭에서 생성된 카드를 확인할 수 있습니다.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 4)

            Spacer()
        }
    }
}

// MARK: - OCR Word Row

private struct OCRWordRow: View {
    @Binding var word: OCRWord

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                word.isSelected.toggle()
            } label: {
                Image(systemName: word.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(word.isSelected ? Color.accentColor : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    TextField("한자", text: $word.kanji)
                        .font(.title3.bold())
                    TextField("読み方", text: $word.reading)
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }
                TextField("의미", text: $word.meaning)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if word.isSelected && (word.kanji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || word.reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || word.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    HStack(spacing: 8) {
                        if word.kanji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Label("한자 확인 필요", systemImage: "exclamationmark.circle")
                        }
                        if word.reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Label("읽기 확인 필요", systemImage: "exclamationmark.circle")
                        }
                        if word.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Label("뜻 확인 필요", systemImage: "exclamationmark.circle")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(word.isSelected ? 1 : 0.45)
    }
}

private struct OCRProcessingNoticeSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    noticeCard(
                        title: "로컬 처리",
                        body: "기본 OCR은 기기 내 Vision으로 처리됩니다. 이 상태에서는 외부 AI 보완을 사용하지 않습니다."
                    )
                    noticeCard(
                        title: "외부 AI 보완",
                        body: "옵션을 켜고 현재 빌드에서 허용된 경우에만 기기 내 OCR로 추출한 단어 텍스트가 보안 프록시 서버로 전송되고, 서버가 Claude API에 전달해 읽기와 뜻 보완에 사용할 수 있습니다. 원본 이미지는 앱 외부로 직접 전송하지 않습니다."
                    )
                    noticeCard(
                        title: "업로드 전 확인",
                        body: "원본 이미지는 외부 전송하지 않더라도, 기기 내 OCR이 민감한 텍스트를 추출할 수 있습니다. 주민등록번호, 연락처, 금융정보, 타인 개인정보가 포함된 이미지는 업로드하지 않는 것을 권장합니다."
                    )
                }
                .padding(24)
            }
            .navigationTitle("OCR 처리 안내")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func noticeCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)

private struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate   = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
