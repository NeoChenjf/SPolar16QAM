import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("rks_evaluate_scope_aware.py")
spec = importlib.util.spec_from_file_location("rks_scope", SCRIPT)
rks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rks)

class ScopeAuditFailureTests(unittest.TestCase):
    def claim_revision_fixture(self, root, second_text="- H1: same", registered=True):
        path="workbook/knowledge/L1/l1_a.md"; target=root/path; target.parent.mkdir(parents=True)
        target.write_text("- **domain_id**: l1_a\n- H1: same\n"
            "Revision metadata: revision_id=old; current_status=current; supersedes=[]\n"
            +second_text+"\nRevision metadata: revision_id=new; current_status=current; supersedes=[old]\n",encoding="utf-8")
        if registered:
            index=root/"workbook/knowledge/meta/current-revisions.json"; index.parent.mkdir(parents=True)
            index.write_text(json.dumps({"documents":[
                {"revision_id":"old","path":path,"status":"historical","supersedes":[]},
                {"revision_id":"new","path":path,"status":"current","supersedes":["old"]}]}))
        return target

    def test_identical_claim_in_registered_history_is_one_claim(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); self.claim_revision_fixture(root)
            self.assertEqual(rks.parse_claims(root),{"l1_a#H1":"workbook/knowledge/L1/l1_a.md"})

    def test_conflicting_claim_in_history_fails(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); self.claim_revision_fixture(root,"- H1: changed")
            with self.assertRaisesRegex(rks.AuditError,"conflicting"): rks.parse_claims(root)

    def test_same_revision_duplicate_claim_fails(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); target=self.claim_revision_fixture(root)
            text=target.read_text(); target.write_text(text.replace("- H1: same\n","- H1: same\n- H1: same\n",1))
            with self.assertRaisesRegex(rks.AuditError,"duplicate"): rks.parse_claims(root)

    def test_unregistered_historical_copy_fails(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); self.claim_revision_fixture(root,registered=False)
            with self.assertRaises(rks.AuditError): rks.parse_claims(root)

    def test_multiline_claim_conflict_is_not_hidden_by_same_header(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); self.claim_revision_fixture(root,"- H1: same\n  changed continuation")
            with self.assertRaisesRegex(rks.AuditError,"conflicting"): rks.parse_claims(root)

    def test_identical_claim_in_unrelated_revisions_fails(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); self.claim_revision_fixture(root)
            path=root/"workbook/knowledge/meta/current-revisions.json"
            data=json.loads(path.read_text()); data["documents"][1]["supersedes"]=[]
            path.write_text(json.dumps(data))
            with self.assertRaisesRegex(rks.AuditError,"unrelated"): rks.parse_claims(root)

    def test_nested_scope_includes_relative_paths_and_excludes_results(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); (root/"src/nested").mkdir(parents=True); (root/"src/results").mkdir()
            (root/"src/a.m").write_text("function a\n")
            (root/"src/nested/a.m").write_text("function a\n")
            (root/"src/results/generated.m").write_text("function generated\n")
            found=[p for p,_ in rks.files(root,["src"],".m")]
            self.assertEqual(found,["src/a.m","src/nested/a.m"])
            excluded=rks.excluded_files(root,["src"],".m")
            self.assertEqual(excluded,["src/results/generated.m"])

    def test_empty_primary_scope_fails_instead_of_scoring_full_coverage(self):
        with self.assertRaisesRegex(rks.AuditError,"empty primary code scope"):
            rks.require_nonempty_primary_scope([])

    def test_same_name_methods_require_distinct_exact_contracts(self):
        paths=["core/decode.m","v3/decode.m"]
        contracts={"workbook/L3/core/l3_decode.md":"- **file_path**: core/decode.m\n"}
        self.assertEqual(rks.method_contract_gaps(paths,contracts),["v3/decode.m"])

    def test_read_failure_is_not_treated_as_empty_success(self):
        with tempfile.TemporaryDirectory() as td:
            bad=Path(td)/"unreadable.md"; bad.write_bytes(b"\xff")
            with self.assertRaisesRegex(rks.AuditError,"cannot read"):
                rks.read(bad)

    def test_malformed_l1_fails_closed(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); (root/"workbook/knowledge/L1").mkdir(parents=True)
            (root/"workbook/knowledge/L1/l1_broken.md").write_text("# missing domain metadata\n")
            with self.assertRaises(rks.AuditError): rks.parse_claims(root)

    def test_empty_claim_set_fails_closed(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); (root/"workbook/knowledge/L1").mkdir(parents=True)
            (root/"workbook/knowledge/L1/l1_empty.md").write_text("- **domain_id**: l1_empty\n")
            with self.assertRaisesRegex(rks.AuditError,"zero parseable hypotheses"): rks.parse_claims(root)

    def test_duplicate_current_revisions_fail(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); target=root/"doc.md"; target.write_text("current\n")
            index=root/"index.json"
            index.write_text(json.dumps({"documents":[
                {"revision_id":"r1","path":"doc.md","status":"current","supersedes":[]},
                {"revision_id":"r2","path":"doc.md","status":"current","supersedes":[]}]}))
            with self.assertRaisesRegex(rks.AuditError,"multiple current revisions"): rks.current_revisions(root,"index.json")

    def test_missing_supersedes_revision_fails(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); (root/"doc.md").write_text("x")
            (root/"index.json").write_text(json.dumps({"documents":[{"revision_id":"r2","path":"doc.md","status":"current","supersedes":["missing"]}]}))
            with self.assertRaisesRegex(rks.AuditError,"supersedes"): rks.current_revisions(root,"index.json")

    def test_wrong_shaped_revision_index_fails_closed(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); (root/"index.json").write_text("[]")
            with self.assertRaisesRegex(rks.AuditError,"root must be an object"):
                rks.current_revisions(root,"index.json")

    def test_current_revision_reader_ignores_historical_append_sections(self):
        text=("old entry\n\nRevision metadata: revision_id=old; current_status=historical; supersedes=[]\n"
              "\nnew entry\n\nRevision metadata: revision_id=new; current_status=current; supersedes=[old]\n")
        self.assertEqual(rks.current_revision_body(text,"new"),"new entry")

    def test_current_revision_reader_fails_when_index_target_has_no_marker(self):
        with self.assertRaisesRegex(rks.AuditError,"marker missing"):
            rks.current_revision_body("unversioned appended content","revision_17")

    def test_unknown_hypothesis_reference_is_rejected(self):
        valid,invalid=rks.validate_l2_claim_refs({"l2.md":"- **validates**: l1_a#H999"},{"l1_a#H1":"l1.md"})
        self.assertEqual(valid,set())
        self.assertEqual(invalid,[("l2.md","l1_a#H999")])

    def test_stale_evidence_target_fails_closed(self):
        with tempfile.TemporaryDirectory() as td:
            index={"allowed_evidence_states":["not_assessed","supporting"],"claims":[
                {"claim_id":"l1_a#H1","evidence_state":"supporting","supporting_evidence":[{"path":"missing.csv"}]}]}
            with self.assertRaisesRegex(rks.AuditError,"evidence target missing"):
                rks.validate_evidence_registry(td,{"l1_a#H1":"l1_a.md"},index)

    def test_existing_historical_file_cannot_promote_claim_without_acceptance_record(self):
        with tempfile.TemporaryDirectory() as td:
            root=Path(td); (root/"history.md").write_text("old result, no acceptance")
            index={"allowed_evidence_states":["not_assessed","supporting"],"claims":[
                {"claim_id":"l1_a#H1","evidence_state":"supporting","supporting_evidence":[{"path":"history.md"}]}]}
            with self.assertRaisesRegex(rks.AuditError,"incomplete evidence record"):
                rks.validate_evidence_registry(root,{"l1_a#H1":"l1_a.md"},index)

    def test_wrong_shaped_claim_registry_fails_closed(self):
        with self.assertRaisesRegex(rks.AuditError,"claims list"):
            rks.validate_evidence_registry(".",{"l1_a#H1":"l1_a.md"},[])

if __name__ == "__main__": unittest.main()
